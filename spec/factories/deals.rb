# -*- encoding : utf-8 -*-

FactoryGirl.define do

  # デフォルトでは太郎の現金→食費
  factory :general_deal, :class => Deal::General do
    user_id Fixtures.identify(:taro)
    summary "ランチ"
    debtor_entries_attributes [:account_id => Fixtures.identify(:taro_food), :amount => 800]
    creditor_entries_attributes [:account_id => Fixtures.identify(:taro_cache), :amount => -800]
    date Date.today
  end
end
