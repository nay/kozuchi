# Proxyと実オブジェクトで共通となるI/Fの実オブジェクト側実装をここに記述する
module Account::Common
  def user_login
    user.login
  end
  def to_summary
    {:ex_id => self.id, :name => self.name, :name_with_user => self.name_with_user, :base_type => self.base_type}
  end
  def destroy_link_request(sender_id, sender_ex_account_id)
    link_request = link_requests.find_by(sender_id: sender_id, sender_ex_account_id: sender_ex_account_id)
    link_requests.delete(link_request) if link_request
  end
#  def create_link_request(sender_id, sender_ex_account_id)
#    link_request = link_requests.find_or_create_by_account_id_and_sender_id_and_sender_ex_account_id(self.id, sender_id, sender_ex_account_id)
#    raise "could not save link_request" if link_request.new_record?
#    link_request
#  end

  def clear_link(skip_requesting = false)
    link.skip_requesting = skip_requesting
    self.link = nil
  end

end