# 勘定にもたせる口座連携関係の機能を記述。
module Account::Linking

  def self.included(base)
    base.has_many :link_requests, -> { includes(:sender) },
                  class_name: "AccountLinkRequest",
                  foreign_key: "account_id",
                  dependent: :destroy
    base.has_one :link, :class_name => "AccountLink", :foreign_key => "account_id", :dependent => :destroy
  end

  # 送受信に関わらず、連携先の設定されている口座かどうかを返す
  def linked?
    self.link != nil || !self.link_requests.empty?
  end

  # 送信先となっている口座（／口座プロキシ）を返す
  # TODO: 名前を変更したい
#  def linked_account(force = false)
  def destination_account(force = false)
    @destination_account = nil if force
    @destination_account ||= (link ? link.target_account : nil)
  end

  # 送受信に関わらず、連携先の口座情報をハッシュの配列で返す。送信があるものを一番上にする。
  def linked_account_summaries(force = false)
    @linked_account_summaries = nil if force
    return @linked_account_summaries if @linked_account_summaries
    summaries = link_requests.map{|r| r.sender_account.to_summary.merge(:from => true, :request_id => r.id)}
    if link
      if interactive = summaries.detect{|s| s[:ex_id] == link.target_ex_account_id}
        interactive[:to] = true
        summaries.delete(interactive)
        summaries.insert(0, interactive)
      else
        summaries.insert(0, link.target_account.to_summary.merge(:to => true))
      end
    end
    @linked_account_summaries = summaries
  end

  # 要請されて、この口座のあるシステムの指定されたEntryと紐づくEntryおよびDealを作成/更新する
  def update_link_to(linked_ex_entry_id, linked_ex_deal_id, linked_user_id, linked_entry_amount, linked_entry_summary, linked_entry_date, linked_ex_entry_confirmed)
    # すでに紐づいたAccountEntryが存在する場合
    my_entry = entries.find_by(linked_ex_entry_id: linked_ex_entry_id, linked_user_id: linked_user_id)
    # 存在し、確認済で金額が同じ（正負逆の同額）なら変更不要
    # 確認状態の変更は別途処理が走る
    if my_entry
      if !my_entry.deal.confirmed? || my_entry.amount != linked_entry_amount * -1
        # 未確認か金額が変わっていた場合は、未確認なら取引を削除、確認済ならリンクを削除する
        # これにより、その相手の処理ではこのifに来ず、mate_entryとして先に処理されたものを発見できる
        my_entry.unlink
        # 同じ取引内に、今回リクエストのあった相手側のDealとすでに紐付いているEntryがあったら、そのリンクも同時に削除する
        my_entry.deal.entries(true).select{|e| e.id != my_entry.id && e.linked_ex_deal_id = linked_ex_deal_id && e.linked_user_id == linked_user_id}.each do |co_linked_entry|
          co_linked_entry.unlink
        end
        my_entry = nil
      end
    else
      mate_entry = user.entries.find_by(linked_ex_deal_id: linked_ex_deal_id, linked_user_id: linked_user_id)
      if mate_entry
        # まだlinked_ex_entry_idが入っていなくても、今回リクエストのあった相手側のDealとすでに紐付いているAccountEntryがあれば、それの相手が求める勘定となる
        # entry数が2でないものはデータ不正
        raise "entry size should be 2" unless mate_entry.deal.entries.size == 2
        my_entry = mate_entry.deal.entries.detect{|e| e.id != mate_entry.id}
        my_entry.account_id = self.id
        my_entry.linked_ex_entry_id = linked_ex_entry_id
        my_entry.linked_ex_deal_id = linked_ex_deal_id
        my_entry.linked_user_id = linked_user_id
        my_entry.linked_ex_entry_confirmed = linked_ex_entry_confirmed
        my_entry.skip_linking = true
        my_entry.save!
      end
    end

    unless my_entry
      # 新しく作成する
      mate_account = self.partner_account || user.default_asset_other_than(self)
      raise "#user #{user.login} 側で相手勘定を決められませんでした" unless mate_account

      deal = Deal::General.new(
        :summary => linked_entry_summary,
        :date => linked_entry_date,
        :confirmed => false)
      deal.user_id = self.user_id
      my_entry = deal.creditor_entries.build(
        :account_id => self.id,
        :amount => linked_entry_amount * -1, :skip_linking => true)
      my_entry.linked_ex_entry_id = linked_ex_entry_id
      my_entry.linked_ex_deal_id = linked_ex_deal_id
      my_entry.linked_user_id = linked_user_id
      my_entry.linked_ex_entry_confirmed = linked_ex_entry_confirmed
      deal.debtor_entries.build(
        :account_id => mate_account.id,
        :amount => linked_entry_amount, :skip_linking => true)
      deal.save!
    end

    # 相手に新しいこちらのAccountEntry情報を送り返す
    return [my_entry.id, my_entry.deal_id, my_entry.deal.confirmed?]
  end

  def unlink_to(linked_ex_entry_id, linked_user_id)
    my_entry = entries.find_by(linked_ex_entry_id: linked_ex_entry_id, linked_user_id: linked_user_id)
    my_entry.unlink if my_entry
  end

  def set_link(target_user, target_account, interactive = false)
    # target_userがリンクを張れる相手かチェックする
    raise PossibleError, "指定されたユーザーが見つからないか、相互にフレンド登録された状態ではありません" unless target_user && user.friend?(target_user)

    # target_ex_account_idがリンクを張れる相手かチェックする
    raise PossibleError, "#{target_user.login}さんには指定された口座がありません。" unless target_account
    target_summary = target_account.to_summary

    # TODO: ex いらない
    target_ex_account_id = target_summary[:ex_id]
    raise PossibleError, "#{self.class.type_name} には #{Account.const_get(target_summary[:base_type].to_s.camelize).type_name} を連動できません。" unless linkable_to?(target_summary[:base_type])

    # 自分側のリンクを作る
    self.link = AccountLink.new(:target_user_id => target_user.id, :target_ex_account_id => target_ex_account_id)
    raise "link could not be saved. #{link.errors.full_messages.join(' ')}" if self.link.new_record?

    # AccountHasDifferentLinkError が発生する場合がある
    target_user.link_account(target_account.id, user_id, id) if interactive

    self.link
  end


end
