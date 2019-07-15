class FixIdSeqs < ActiveRecord::Migration[5.2]
  def change
    [
        :account_entries, :account_link_requests, :account_links, :accounts,
        :deal_patterns, :deals, :entry_patterns, :friend_permissions, :friend_requests,
        :preferences, :sessions, :settlements, :single_logins, :users
    ].each do |table_name|
      execute "SELECT setval('#{table_name}_id_seq', (SELECT MAX(id) FROM #{table_name}));"
    end
  end
end
