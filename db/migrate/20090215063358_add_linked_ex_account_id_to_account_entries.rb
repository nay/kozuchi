class AddLinkedExAccountIdToAccountEntries < ActiveRecord::Migration
  def self.up
    add_column :account_entries, :linked_ex_entry_id, :integer
    add_column :account_entries, :linked_ex_deal_id, :integer
    add_column :account_entries, :linked_user_id, :integer
    # すでに登録されているdeal_linksをすべて検索し、これを抱えるAccountEntryの上記カラムにお互いを登録していく。
    for deal_link_id in execute "select id from deal_links"
      entries = []
      for account_entry_id, deal_id, user_id in execute "select id, deal_id, user_id from account_entries where friend_link_id = #{deal_link_id}"
        entries << {:entry_id => account_entry_id, :deal_id => deal_id, :user_id => user_id}
      end
      if entries.size != 2
        p "There is invalid data for deal_link #{deal_link_id}. entries size is #{entries.size}. Skiped this deal_link."
        next
      end
      execute "update account_entries set linked_ex_entry_id = #{entries.first[:entry_id]}, linked_ex_deal_id = #{entries.first[:deal_id]}, linked_user_id = #{entries.first[:user_id]} where id = #{entries.last[:entry_id]}"
      execute "update account_entries set linked_ex_entry_id = #{entries.last[:entry_id]}, linked_ex_deal_id = #{entries.last[:deal_id]}, linked_user_id = #{entries.last[:user_id]} where id = #{entries.first[:entry_id]}"
    end
  end

  def self.down
    remove_column :account_entries, :linked_user_id
    remove_column :account_entries, :linked_ex_deal_id
    remove_column :account_entries, :linked_ex_entry_id
  end
end
