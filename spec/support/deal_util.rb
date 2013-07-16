# -*- encoding : utf-8 -*-
# Deal 関係のユーティリティメソッド

# 口座idを取得するためのユーティリティ fixture名またはレコードを渡す
def to_account_id(value)
  case value
  when Symbol
    Fixtures.identify(value)
  when ActiveRecord::Base
    value.id
  else
    value
  end
end

# 単純明細記入の作成
def new_simple_deal(month, day, from, to, amount, year = 2008)
  d = Deal::General.new(:summary => "#{month}/#{day}の買い物",
    :debtor_entries_attributes => [:account_id => to_account_id(to), :amount => amount],
    :creditor_entries_attributes => [:account_id => to_account_id(from), :amount => amount * -1],
    :date => Date.new(year, month, day))
  to_account = Account::Base.find(to_account_id(to))
  d.user_id = to_account.user_id
  d
end

# 複数明細記入の作成
# debtors {account_id => amout, account_id => amount} のように記述
# [account_id, amount]の配列でも可
def new_complex_deal(month, day, debtors, creditors, options = {})
  summary = options[:summary] || "#{month}/#{day}の記入"
  date = Date.new(options[:year] || 2010, month, day)

  deal = Deal::General.new(:summary => summary, :summary_mode => 'unify', :date => date,
    :debtor_entries_attributes => debtors.map{|key, value| {:account_id => (key.kind_of?(Symbol) ? Fixtures.identify(key) : key), :amount => value}}.each_with_index{|e, i| e[:line_number] = i},
    :creditor_entries_attributes => creditors.map{|key, value| {:account_id => (key.kind_of?(Symbol) ? Fixtures.identify(key) : key), :amount => value}}.each_with_index{|e, i| e[:line_number] = i}
  )

  key = debtors.respond_to?(:keys) ? debtors.keys.first : debtors.first.first
  account_id = key.kind_of?(Symbol) ? Fixtures.identify(key) : key
  account = Account::Base.find_by_id(account_id)
  raise "no account" unless account
  deal.user_id = account.user_id
  deal
end
