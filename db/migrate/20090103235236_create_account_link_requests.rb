class CreateAccountLinkRequests < ActiveRecord::Migration
  def self.up
    create_table :account_link_requests do |t|
      t.integer :account_id
      t.integer :sender_id
      t.integer :sender_ex_account_id

      t.timestamps
    end
    # Make Records
    # target_ex_account_idのあるaccountに対して、相手側Requestを作る
    for account_id, user_id, target_ex_account_id in execute "select account_id, accounts.user_id, target_ex_account_id from account_links inner join accounts on accounts.id = account_links.account_id"
      execute("insert into account_link_requests (account_id, sender_id, sender_ex_account_id, created_at, updated_at) values (#{target_ex_account_id}, #{user_id}, #{account_id}, now(), now())")
    end
  end

  def self.down
    drop_table :account_link_requests
  end
end
