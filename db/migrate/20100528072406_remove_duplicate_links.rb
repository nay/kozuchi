# -*- encoding : utf-8 -*-

class RemoveDuplicateLinks < ActiveRecord::Migration[5.0]
  def self.up
    for account_id, id in execute("select account_id, min(id) as count from account_links group by account_id") do
      execute("delete from account_links where account_id = #{account_id} and id != #{id}")
    end
    invalid_account_link_requests = []
    for id, remote_id in execute "select account_link_requests.id, account_links.id as remote_id from account_link_requests left outer join account_links on account_links.user_id = account_link_requests.sender_id and account_links.account_id = account_link_requests.sender_ex_account_id where account_links.id is null"
      invalid_account_link_requests << id.to_s
    end
    execute("delete from account_link_requests where id in (#{invalid_account_link_requests.join(',')})") unless invalid_account_link_requests.empty?
  end

  def self.down
  end
end
