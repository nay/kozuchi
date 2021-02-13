FactoryBot.define do
  factory :entry_pattern, :class => Pattern::Entry do
    user_id    { Fixtures.identify(:taro) }
    account_id { Fixtures.identify(:taro_cache) }
    amount     { '-1000' }
    summary    { '昼食' }
  end
end
