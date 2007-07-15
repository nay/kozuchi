require File.dirname(__FILE__) + '/../../test_helper'

# require File.dirname(__FILE__) + '/../../../../app/models/account/base'
class Account::BaseTest < Test::Unit::TestCase
  self.use_instantiated_fixtures  = false
  fixtures :users, "account/accounts"
  set_fixture_class  "account/accounts".to_sym => 'account/base'
  fixtures :preferences
  fixtures :account_rules
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
  
  # ----- 新規登録のテスト
  
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
  
  # ----- 削除可能性事前チェックのテスト
  
  # 使われていないのは消せる
  def test_deletable
    a = Account::Base.find(10)
    assert_equal true, a.deletable?
    assert a.delete_errors.empty?
  end
  
  # 使われていたら消せない
  def test_deletable_used
    d = Deal.new(:user_id => 1, :minus_account_id => 1, :plus_account_id => 10, :amount => 2000, :date => Date.new(2007, 1, 1), :summary => "", :confirmed => true)
    d.save!
    a = Account::Base.find(10)
    assert_equal false, a.deletable?
    assert_equal 1, a.delete_errors.size
    assert_equal Account::UsedAccountException.new_message('口座', '貯金箱'), a.delete_errors[0]
  end
  
  # 精算先口座に指定されていたら消せない
  def test_deletable_rule_associated
    a = Account::Base.find(7)
    assert_equal false, a.deletable?
    assert_equal 1, a.delete_errors.size
    assert_equal Account::RuleAssociatedAccountException.new_message('銀行'), a.delete_errors[0]
  end

  # 精算先口座に指定されていたら消せない。データもある場合は２つエラーが用意できる。
  def test_deletable_rule_associated
    d = Deal.new(:user_id => 1, :minus_account_id => 1, :plus_account_id => 7, :amount => 2000, :date => Date.new(2007, 1, 1), :summary => "", :confirmed => true)
    d.save!
    a = Account::Base.find(7)
    assert_equal false, a.associated_account_rules.empty?
    assert_equal false, a.deletable?
    assert_equal 2, a.delete_errors.size
    assert_equal Account::UsedAccountException.new_message('口座', '銀行'), a.delete_errors[0]
    assert_equal Account::RuleAssociatedAccountException.new_message('銀行'), a.delete_errors[1]
  end

  
  # ----- 削除のテスト
 
  # 使われていないものが消せるテスト
  def test_delete
    a = Account::Base.find(10)
    assert_nothing_raised {a.destroy}
  end
  
  # データが使われていたら消せないことのテスト
  def test_delete_used
    d = Deal.new(:user_id => 1, :minus_account_id => 1, :plus_account_id => 10, :amount => 2000, :date => Date.new(2007, 1, 1), :summary => "", :confirmed => true)
    d.save!
    a = Account::Base.find(10)
    assert_raise(Account::UsedAccountException) {a.destroy}
    assert_nothing_raised {Account::Base.find(10)}
  end

  # [1vs1精算]
  #
  # 精算先口座に指定されていたら消せないことのテスト
  def test_delete_rule_associated
    a = Account::Base.find(7)
    assert_raise(Account::RuleAssociatedAccountException) {a.destroy}
    assert_nothing_raised {Account::Base.find(7)}
  end
  
  # [1vs1精算]
  # 
  # 精算対象口座に指定されていたらルールも一緒に消されることのテスト
  def test_delete_with_rule
    assert_not_nil AccountRule.find(1)
    a = Account::Base.find(6)
    a.destroy
    assert_raise(ActiveRecord::RecordNotFound) {AccountRule.find(1)}
  end
  
  # 更新のテスト

  # 勘定名を変えられることのテスト
  def test_change_name
    a = Account::Base.find(7)
    a.name = "新しい名前"
    assert a.save
  end
  
  # changable_asset_types のテスト

  # buisness_flag ONで何も関連がないときは、どの口座からもすべての口座に変更できることを確認する
  def test_changable_asset_types_all_with_business_use
    # 全種類つくる
    count = 1
    for type in Account::Asset.types
      a = type.new(:name => "テスト口座#{count}", :user_id => 2)
      a.save!
      options = a.changable_asset_types
      for target_type in Account::Asset.types
        assert options.include?(target_type), "#{target_type} must be included in #{options} for #{type}."
      end
      count += 1
    end
  end
  
  # buisness_flag OFFで何も関連がないときは、資本以外のどの口座からも、資本以外のすべての口座に変更できることを確認する
  def test_changable_asset_types_all_without_business_use
    # 全種類つくる
    count = 1
    for type in Account::Asset.types
      next if type == Account::CapitalFund
      a = type.new(:name => "テスト口座#{count}", :user_id => 1)
      a.save!
      options = a.changable_asset_types
      for target_type in Account::Asset.types
        next if target_type == Account::CapitalFund
        assert options.include?(target_type), "#{target_type} must be included in #{options} for #{type}."
      end
      assert_equal false, options.include?(Account::CapitalFund), "Account::CapitalFund should not be included in #{options}"
      count += 1
    end
  end
  
  # 精算先口座になっている場合は金融機関口座にしかならない（実装マター）ことを確認する
  def chanbale_asset_types_for_rule_associated
    a = Account.find(7)
    assert_equal 1, a.changable_asset_types.size
    assert_equal Account::BankingFacility, a.changable_asset_types[0]
  end

  # 精算対象口座になっている場合はCredit, CreditCardにしかならない（実装マター）ことを確認する
  def chanbale_asset_types_for_rule_associated
    a = Account.find(6)
    options = a.changable_asset_types
    assert_equal 2, options.size
    assert options.include?(Account::CreditCard)
    assert options.include?(Account::Credit)
  end

end
