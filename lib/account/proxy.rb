# 外部にある勘定への操作の受け口となるクラス。まだ使わないがメモとして。
class Account::Proxy

  attr_accessor :user, :id, :name
  def initialize(user_proxy, account_id, account_name)
    self.user = user_proxy
    self.id = account_id
    self.name = account_name
  end

  def to_summary
    # TODO: キャッシュされていなければ通信して取ってくる
    raise "Not Supported"
  end
  
  def clear_link(skip_requesting = false)
    raise "Not Supported"
  end

  def set_link(target_user_login, target_ex_account_name, interactive = false, skip_requesting = false)
    raise "not Supported"
  end

  def id
    raise "not Supported"
  end

  def user_id
    # 翻訳して返す
    raise "not Supported"
  end

  def user_login
    raise "not Supported"
  end

end