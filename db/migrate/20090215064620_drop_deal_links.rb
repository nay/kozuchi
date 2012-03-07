# -*- encoding : utf-8 -*-

class DropDealLinks < ActiveRecord::Migration
  def self.up
    drop_table :deal_links
    remove_column :account_entries, :friend_link_id
  end

  def self.down
    add_column :account_entries, :friend_link_id, :integer
    create_table "deal_links", :force => true do |t|
      t.integer "created_user_id", :limit => 11
    end
    # 注意：将来予定している遠隔接続のデータがあると完全には復元できない
    for id, user_id, linked_ex_entry_id, linked_user_id, friend_link_id in execute "select id, user_id, linked_ex_entry_id, linked_user_id, friend_link_id from account_entries where linked_ex_entry_id is not null"
      # すでにfriend_link_idがあったら飛ばす
      friend_link_exist = false
      for friend_link in execute "select friend_link_id from account_entries where id = #{id} and friend_link_id is not null"
        friend_link_exist = true
      end
      next if friend_link_exist
      # まだなければfriend_linkを作成
      execute "insert into deal_links () values ()"
      # 最新のfriend_linkのidをとってきて、自分と相手にセットする
      for friend_link_id in execute "select max(id) from deal_links"
        execute "update account_entries set friend_link_id = #{friend_link_id} where (id = #{id} and user_id = #{user_id}) or (id = #{linked_ex_entry_id} and user_id = #{linked_user_id})"
      end
    end
  end
end
