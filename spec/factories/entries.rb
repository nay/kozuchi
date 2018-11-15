# -*- encoding : utf-8 -*-
FactoryBot.define do
  factory :general_entry, :class => Entry::General do
    user_id    { Fixtures.identify(:taro) }
    account_id { Fixtures.identify(:taro_cache) }
    amount     { '800' }
    summary    { "ランチ" }
    date       { Date.today }
    daily_seq  { 1 }
  end

  factory :balance_entry, :class => Entry::Balance do
    user_id    { Fixtures.identify(:taro) }
    account_id { Fixtures.identify(:taro_cache) }
    balance    { '800' }
    summary    { "ランチ" }
    date       { Date.today }
    daily_seq  { 1 }
  end
end