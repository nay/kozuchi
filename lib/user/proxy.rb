# TODO: まだ使わないがメモとして。使う際はログインを使うのでSTIか。
class User::Proxy
  def account(account_id)
    Account::Proxy.new(self, account_id, nil)
  end
  def account_by_name(account_name)
    Account::Proxy.new(self, account_id, nil, account_name)
  end
end