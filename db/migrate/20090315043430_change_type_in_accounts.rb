# -*- encoding : utf-8 -*-

class ChangeTypeInAccounts < ActiveRecord::Migration
  def self.up
    # Income, Expense 以外を Assetにする。
    for id in execute "select id from accounts where type not in ('Income', 'Account::Income', 'Expense', 'Account::Expense')"
      execute("update accounts set type = 'Asset' where id = #{id}")
    end
  end

  def self.down
    # asset_kindからtype値をもとに戻す。
    for id, asset_kind in execute "select id, asset_kind from accounts where asset_kind is not null"
      execute("update accounts set type = '#{asset_kind.classify}' where id = #{id}")
    end
  end
end
