# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :deal_pattern, :class => Pattern::Deal do
    user_id                     { Fixtures.identify(:taro) }
    code                        { "001" }
    name                        { "給料" }
    debtor_entries_attributes   { [{:line_number => 0, :account_id => Fixtures.identify(:taro_bank), :summary => '給料', :amount => 210000 }, { :line_number => 1, :account_id => Fixtures.identify(:taro_tax), :amount => 20000, :summary => '所得税'}] }
    creditor_entries_attributes { [:line_number => 0, :account_id => Fixtures.identify(:taro_salary), :summary => '給料', :amount => -230000] }
  end
end
