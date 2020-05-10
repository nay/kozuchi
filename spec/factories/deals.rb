FactoryBot.define do

  # 単純な記入
  # デフォルトでは太郎の現金→食費
  factory :general_deal, :class => Deal::General do
    transient do
      creditor_account_id { Fixtures.identify(:taro_cache) }
    end
    trait :cache do
      creditor_account_id { Fixtures.identify(:taro_cache) }
    end
    trait :card do
      creditor_account_id { Fixtures.identify(:taro_card) }
    end
    user_id                     { Fixtures.identify(:taro) }
    summary                     { "ランチ" }
    summary_mode                { 'unify' }
    debtor_entries_attributes   { [:account_id => Fixtures.identify(:taro_food), :amount => 800] }
    creditor_entries_attributes { [:account_id => creditor_account_id, :amount => -800] }
    date                        { Time.zone.today }
  end

  # 複数記入
  factory :complex_deal, :class => Deal::General do
    transient do
      creditor_account_id { Fixtures.identify(:taro_cache) }
    end
    trait :cache do
      creditor_account_id { Fixtures.identify(:taro_cache) }
    end
    trait :card do
      creditor_account_id { Fixtures.identify(:taro_card) }
    end
    user_id                     { Fixtures.identify(:taro) }
    summary                     { '買い物' }
    summary_mode                { 'unify' }
    debtor_entries_attributes   { [{:account_id => Fixtures.identify(:taro_food), :amount => 800, :line_number => 0}, {:account_id => Fixtures.identify(:taro_other), :amount => 200, :line_number => 1}] }
    creditor_entries_attributes { [:account_id => creditor_account_id, :amount => -1000, :line_number => 0] }
    date                        { Time.zone.today }
  end

  # 残高記入
  factory :balance_deal, :class => Deal::Balance do
    user_id    { Fixtures.identify(:taro) }
    account_id { Fixtures.identify(:taro_cache) }
    balance    { 5431 }
    date       { Time.zone.today }
  end

end
