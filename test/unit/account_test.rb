require File.dirname(__FILE__) + '/../test_helper'

class AccountTest < Test::Unit::TestCase
  self.use_instantiated_fixtures  = false
  fixtures :users
  fixtures :friends
  fixtures :accounts
  fixtures :account_links

  # 不正な connect で例外が正しくでることをテストする
  # TODO: そこまでいかない・・・
#  def test_wrong_connect
#    account = Account.find(1)
#    assert_raise(RuntimeError) do
#      account.connect(2, '食費')
#    end
#  end

  def test_default_asset
    assert_equal 1, Account.find_default_asset(1).id
  end

  def test_name_with_asset_type
    assert_equal '現金(現金)', Account.find(1).name_with_asset_type
    assert_equal '食費(支出)', Account.find(2).name_with_asset_type
    assert_equal 'ボーナス(収入)', Account.find(8).name_with_asset_type
  end
  
  # デフォルト口座登録がエラーなく動くことを確認する
  def test_create_default_accounts
    Account.delete_all('user_id = 2')
    Account.create_default_accounts(2)
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
  def test_wrong_partner_account
    account = Account.find(1)
    wrong_partner_account = Account.find(4)
    account.partner_account_id = wrong_partner_account.id
    is_error = false
    begin
      account.save!
    rescue
      is_error = true
    end
    assert is_error
  end
end
