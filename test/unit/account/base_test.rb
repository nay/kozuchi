require File.dirname(__FILE__) + '/../../test_helper'

require File.dirname(__FILE__) + '/../../../../app/models/account/base'
class Account::BaseTest < Test::Unit::TestCase

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

end
