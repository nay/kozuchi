# Proxyと実オブジェクトで共通となるI/Fの実オブジェクト側実装をここに記述する
module Account::Common
  def user_login
    user.login
  end
  def to_summary
    {:ex_id => self.id, :name => self.name, :name_with_user => self.name_with_user, :base_type => self.base_type}
  end
  def destroy_link_request(sender_id, sender_ex_account_id)
    link_request = link_requests.find_by_sender_id_and_sender_ex_account_id(sender_id, sender_ex_account_id)
    link_requests.delete(link_request) if link_request
  end
  def create_link_request(sender_id, sender_ex_account_id)
    link_request = link_requests.find_or_create_by_account_id_and_sender_id_and_sender_ex_account_id(self.id, sender_id, sender_ex_account_id)
    raise "could not save link_request" if link_request.new_record?
    link_request
  end

  def clear_link(skip_requesting = false)
    link.skip_requesting = skip_requesting
    self.link = nil
  end
  def set_link(target_user_login, target_ex_account_name, interactive = false, skip_requesting = false)
    # target_userがリンクを張れる相手かチェックする
    target_user = User.find_by_login(target_user_login)
    raise PossibleError, "指定されたユーザーが見つからないか、相互にフレンド登録された状態ではありません" unless target_user && user.friend?(target_user)

    # target_ex_account_idがリンクを張れる相手かチェックする
    target_account = target_user.account_by_name(target_ex_account_name)
    unless target_account
      raise PossibleError, "フレンド #{target_user.login} さんには #{target_ex_account_name} がありません。"
    end
    target_summary = target_account.to_summary

    target_ex_account_id = target_summary[:ex_id]
    raise PossibleError, "#{self.class.type_name} には #{Account.const_get(target_summary[:base_type].to_s.camelize).type_name} を連動できません。" unless linkable_to?(target_summary[:base_type])

    # 自分側のリンクを作る
    new_link = AccountLink.new(:skip_requesting => skip_requesting)
    new_link.user_id = self.user_id
    new_link.target_user_id = target_user.id
    new_link.target_ex_account_id = target_ex_account_id
    # TODO: attr_protectedいらなかったかも↑
    self.link = new_link # 相手のrequestはコールバックで作られる
    raise "link could not be saved" if self.link.new_record?

    if interactive
      # 相手側のリンクを作る。相手側のリンクを作れたら、自分のRequestは自分で作る
      target_account.set_link(user.login, name)
      create_link_request(target_user.id, target_ex_account_id)
    end

    return target_summary
  end
end