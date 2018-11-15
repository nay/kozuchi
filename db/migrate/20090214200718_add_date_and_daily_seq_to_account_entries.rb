# -*- encoding : utf-8 -*-

class AddDateAndDailySeqToAccountEntries < ActiveRecord::Migration[5.0]
  def self.up
    add_column :account_entries, :date, :date, :null => false
    add_column :account_entries, :daily_seq, :integer, :null => false
    # 紐付いているdealの値をコピーする
    for deal_id, date, daily_seq in execute "select id, date, daily_seq from deals"
      execute ActiveRecord::Base.sanitize_sql_array(
        ["update account_entries set date = ?, daily_seq = ? where deal_id = ?", date, daily_seq, deal_id])
    end
  end

  def self.down
    remove_column :account_entries, :date, :date
    remove_column :account_entries, :daily_seq, :integer
  end
end
