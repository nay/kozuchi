require File.dirname(__FILE__) + '/../test_helper'

class Account::BaseTest < ActiveSupport::TestCase

  # クラスレベルの定義が正しく動くことをテストする
  def test_class_definitions
    assert_equal [Account::Asset, Account::Expense, Account::Income], Account::Base.types
    assert_equal '費目', Account::Expense.type_name
    assert_equal '支出', Account::Expense.short_name
    assert_equal Account::Income, Account::Expense.connectable_type

    assert_equal Account::Cache, Account::Asset.types.first
    assert_equal '口座', Account::Cache.type_name
    assert_equal '口座', Account::Cache.short_name
    assert_equal Account::Asset, Account::Cache.connectable_type
    assert_equal '現金', Account::Cache.asset_name
    assert_equal false, Account::Cache.rule_applicable?
    assert_equal false, Account::Cache.business_only?
    assert Account::CreditCard.rule_applicable?
    assert Account::CapitalFund.business_only?
  end

  def test_type_in
    cache = Account::Cache.new
    assert cache.type_in?(:cache)
    assert_equal false, cache.type_in?(:credit)
    assert cache.type_in?(:asset)
    assert_equal false, cache.type_in?(:income)
  end

  def test_name_with_asset_type
    assert_equal '現金(現金)', accounts(:first_cache).name_with_asset_type
    assert_equal '食費(支出)', accounts(:first_food).name_with_asset_type
    assert_equal 'ボーナス(収入)', accounts(:first_bonus).name_with_asset_type
  end

  # デフォルト口座登録がエラーなく動くことを確認する
  def test_create_default_accounts
    Account::Base.delete_all("user_id = #{users(:old2).id}")
    Account::Base.create_default_accounts(users(:old2).id)
    user = users(:old2)
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
    account = accounts(:first_cache)
    wrong_partner_account = accounts(:second_cache)
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
    account = Account::Cache.new(:user_id => users(:old).id)
    assert_equal false, account.save
  end
  
  # 同じ名前で登録できないことのテスト
  def test_same_name
    account = Account::Cache.new(:user_id => users(:old).id, :name => '現金')
    assert_equal false, account.save
    assert_equal 1, account.errors.size
    assert_equal "口座・費目・収入内訳で名前が重複しています。", account.errors[:name]
  end
  
  # ----- 削除可能性事前チェックのテスト
  
  # 使われていないのは消せる
  def test_deletable
    a = accounts(:deletable_one)
    assert_equal true, a.deletable?
    assert a.delete_errors.empty?
  end
  
  # 使われていたら消せない
  def test_deletable_used
    d = Deal.new(:user_id => users(:old).id, :minus_account_id => accounts(:first_cache).id, :plus_account_id => accounts(:deletable_one).id, :amount => 2000, :date => Date.new(2007, 1, 1), :summary => "", :confirmed => true)
    d.save!
    a = accounts(:deletable_one)
    assert_equal false, a.deletable?
    assert_equal 1, a.delete_errors.size
    assert_equal Account::UsedAccountException.new_message('口座', '貯金箱'), a.delete_errors[0]
  end
  
  # 精算先口座に指定されていたら消せない
  def test_deletable_rule_associated
    a = accounts(:first_bank)
    assert_equal false, a.deletable?
    assert_equal 1, a.delete_errors.size
    assert_equal Account::RuleAssociatedAccountException.new_message('銀行'), a.delete_errors[0]
  end

  # 精算先口座に指定されていたら消せない。データもある場合は２つエラーが用意できる。
  def test_deletable_rule_associated
    d = Deal.new(:user_id => users(:old).id, :minus_account_id => accounts(:first_cache).id, :plus_account_id => accounts(:first_bank).id, :amount => 2000, :date => Date.new(2007, 1, 1), :summary => "", :confirmed => true)
    d.save!
    a = accounts(:first_bank)
    assert_equal false, a.associated_account_rules.empty?
    assert_equal false, a.deletable?
    assert_equal 2, a.delete_errors.size
    assert_equal Account::UsedAccountException.new_message('口座', '銀行'), a.delete_errors[0]
    assert_equal Account::RuleAssociatedAccountException.new_message('銀行'), a.delete_errors[1]
  end

  
  # ----- 削除のテスト
 
  # 使われていないものが消せるテスト
  def test_delete
    a = accounts(:deletable_one)
    assert_nothing_raised {a.destroy}
  end
  
  # データが使われていたら消せないことのテスト
  def test_delete_used
    d = Deal.new(:user_id => users(:old), :minus_account_id => accounts(:first_cache).id, :plus_account_id => accounts(:deletable_one).id, :amount => 2000, :date => Date.new(2007, 1, 1), :summary => "", :confirmed => true)
    d.save!
    a = accounts(:deletable_one)
    assert_raise(Account::UsedAccountException) {a.destroy}
    assert_nothing_raised {Account::Base.find(a.id)}
  end

  # [1vs1精算]
  #
  # 精算先口座に指定されていたら消せないことのテスト
  def test_delete_rule_associated
    a = accounts(:first_bank)
    assert_raise(Account::RuleAssociatedAccountException) {a.destroy}
    assert_nothing_raised {Account::Base.find(a.id)}
  end
  
  # [1vs1精算]
  # 
  # 精算対象口座に指定されていたらルールも一緒に消されることのテスト
  def test_delete_with_rule
    r = account_rules(:first_account_rule)
    assert_not_nil r
    a = accounts(:first_credit_card)
    a.destroy
    assert_raise(ActiveRecord::RecordNotFound) {AccountRule.find(r.id)}
  end
  
 # 更新のテスト

 # 勘定名を変えられることのテスト
  def test_change_name
    a = accounts(:first_bank)
    a.name = "新しい名前"
    assert a.save
  end
 
 # changable_asset_types のテスト

  # buisness_flag ONで何も関連がないときは、どの口座からもすべての口座に変更できることを確認する
  def test_changable_asset_types_all_with_business_use
    # 全種類つくる
    count = 1
    for type in Account::Asset.types
      a = type.new(:name => "テスト口座#{count}", :user_id => users(:old2).id)
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
      a = type.new(:name => "テスト口座#{count}", :user_id => users(:old).id)
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
