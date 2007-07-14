require File.dirname(__FILE__) + '/../../test_helper'

# require File.dirname(__FILE__) + '/../../../../app/models/account/base'
class Account::BaseTest < Test::Unit::TestCase
  self.use_instantiated_fixtures  = false
  fixtures :users, "account/accounts"
  set_fixture_class  "account/accounts".to_sym => 'account/base'
  fixtures :friends
  fixtures :account_links

  # クラスレベルの定義が正しく動くことをテストする
  def test_class_definitions
    assert_equal [Asset, Expense, Income], Account::Base.types
    assert_equal '費目', Expense.type_name
    assert_equal '支出', Expense.short_name
    assert_equal Income, Expense.connectable_type

    assert_equal Cache, Asset.types.first
    assert_equal '口座', Cache.type_name
    assert_equal '口座', Cache.short_name
    assert_equal Asset, Cache.connectable_type
    assert_equal '現金', Cache.asset_name
    assert_equal false, Cache.rule_applicable?
    assert_equal false, Cache.business_only?
    assert CreditCard.rule_applicable?
    assert CapitalFund.business_only?
  end

  def test_type_in
    cache = Account::Cache.new
    assert cache.type_in?(:cache)
    assert_equal false, cache.type_in?(:credit)
    assert cache.type_in?(:asset)
    assert_equal false, cache.type_in?(:income)
  end

  def test_name_with_asset_type
    assert_equal '現金(現金)', Account::Base.find(1).name_with_asset_type
    assert_equal '食費(支出)', Account::Base.find(2).name_with_asset_type
    assert_equal 'ボーナス(収入)', Account::Base.find(8).name_with_asset_type
  end

  # デフォルト口座登録がエラーなく動くことを確認する
  def test_create_default_accounts
    Account::Base.delete_all('user_id = 2')
    Account::Base.create_default_accounts(2)
    user = User.find(2)
    assert_equal 1, user.accounts.types_in(:asset).size
    a = user.accounts.types_in(:asset)[0]
    assert_equal '現金', a.name
    assert_equal 1, a.sort_key
    assert_equal 17, user.accounts.types_in(:expense).size
    a = user.accounts.types_in(:expense)[16]
    assert_equal '自動車関連費', a.name
    assert_equal 17, a.sort_key
    assert_equal 4, user.accounts.types_in(:income).size
  end

  # tests partner account error
  # 違うユーザーの口座を受け皿に設定できないことのテスト
  def test_wrong_partner_account
    account = Account::Base.find(1)
    wrong_partner_account = Account::Base.find(4)
    assert account.user_id != wrong_partner_account.user_id

    account.partner_account_id = wrong_partner_account.id
    is_error = false
    begin
      account.save!
    rescue
      is_error = true
    end
    assert is_error
  end
  
  # 名前が空で登録できないことのテスト
  def test_empty_name
    account = Account::Cache.new(:user_id => 1)
    assert_equal false, account.save
  end
  
  # 同じ名前で登録できないことのテスト
  def test_same_name
    account = Account::Cache.new(:user_id => 1, :name => '現金')
    assert_equal false, account.save
    assert_equal 1, account.errors.size
    assert_equal "口座・費目・収入内訳で名前が重複しています。", account.errors[:name]
  end


end
