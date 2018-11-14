# -*- encoding : utf-8 -*-

class AddUserIdToAccountLinkRequest < ActiveRecord::Migration[5.0]
  def self.up
    add_column :account_link_requests, :user_id, :integer
    for id, user_id in execute("select account_link_requests.id, accounts.user_id from account_link_requests inner join accounts on account_link_requests.account_id = accounts.id")
      execute("update account_link_requests set user_id = #{user_id} where id = #{id}")
    end
  end

  def self.down
    remove_column :account_link_requests, :user_id
  end
end
