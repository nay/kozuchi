class RemoveDuplicateLinks < ActiveRecord::Migration
  def self.up
    for account_id, id in execute("select account_id, min(id) as count from account_links group by account_id") do
      execute("delete from account_links where account_id = #{account_id} and id != #{id}")
    end
  end

  def self.down
  end
end
