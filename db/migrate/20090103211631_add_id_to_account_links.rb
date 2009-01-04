class AddIdToAccountLinks < ActiveRecord::Migration
  def self.up
    # データをメモリに格納しておく
    data = []
    for account_id, target_ex_account_id, target_user_id, user_id in execute "select account_id, connected_account_id, connected_accounts.user_id, accounts.user_id from account_links inner join accounts as connected_accounts on account_links.connected_account_id = connected_accounts.id inner join accounts on account_links.account_id = accounts.id"
      data << {:account_id => account_id, :user_id => user_id, :target_user_id => target_user_id, :target_ex_account_id => target_ex_account_id}
    end
    p data.inspect
    remove_index :account_links, :name => "account_links_connected_account_id_index"
    drop_table "account_links"
    create_table "account_links" do |t|
      t.integer :user_id
      t.integer :account_id
      t.integer :target_user_id
      t.integer :target_ex_account_id

      t.timestamps
    end
    add_index "account_links", ["target_ex_account_id"], :name => "account_links_target_ex_account_id_index"
    for hash in data
      execute("insert into account_links (user_id, account_id, target_user_id, target_ex_account_id, created_at, updated_at) values (#{hash[:user_id]}, #{hash[:account_id]}, #{hash[:target_user_id]}, #{hash[:target_ex_account_id]}, now(), now())")
    end
  end

  def self.down
    # データをメモリに残しておく
    data = []
    for account_id, user_id, target_user_id, target_ex_account_id in execute "select account_id, user_id, target_user_id, target_ex_account_id from account_links"
      data << {:account_id => account_id, :user_id => user_id, :target_user_id => target_user_id, :target_ex_account_id => target_ex_account_id}
    end
    remove_index :account_links, :name => "account_links_target_ex_account_id_index"
    drop_table "account_links"
    create_table "account_links", :id => false, :force => true do |t|
      t.integer "account_id",           :limit => 11, :null => false
      t.integer "connected_account_id", :limit => 11, :null => false
    end

    for hash in data
      execute("insert into account_links (account_id, connected_account_id) values (#{hash[:account_id]}, #{hash[:target_ex_account_id]})")
    end

    add_index "account_links", ["connected_account_id"], :name => "account_links_connected_account_id_index"
  end
end
