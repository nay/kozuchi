class InitialSchema < ActiveRecord::Migration

  def self.up
  
    # users
    create_table("users") do |t|
      t.column "login", :string, :limit => 80, :default => '', :null => false
      t.column "salted_password", :string, :limit => 40, :default => '', :null => false
      t.column "email", :string, :limit => 60, :default => '', :null => false
      t.column "firstname", :string, :limit => 40
      t.column "lastname", :string, :limit => 40
      t.column "salt", :string, :limit => 40, :default => '', :null => false
      t.column "verified", :integer, :default => 0
      t.column "role", :string, :limit => 40
      t.column "security_token", :string, :limit => 40
      t.column "token_expiry", :datetime
      t.column "created_at", :timestamp
      t.column "updated_at", :timestamp
      t.column "logged_in_at", :timestamp
      t.column "deleted", :integer, :default => 0
      t.column "delete_after", :timestamp
    end

    # friends
    create_table("friends") do |t|
      t.column "user_id", :integer, :null => false
      t.column "friend_user_id", :integer, :null => false
      t.column "friend_level", :integer, :default => 1, :null => false
    end

    # accounts
    create_table("accounts") do |t|
      t.column "user_id", :integer, :null => false
      t.column "name", :string, :limit => 32, :null => false
      t.column "account_type", :integer, :null => false
      t.column "asset_type", :integer
      t.column "sort_key", :integer
      t.column "partner_account_id", :integer
      # foreign key (user_id) references users
    end

    #deals
    create_table("deals") do |t|
      t.column "type", :string, :limit => 20, :null => false
      t.column "user_id", :integer, :null => false
      t.column "date", :date, :null => false
      t.column "daily_seq", :integer, :null => false
      t.column "summary", :string, :limit => 64, :null => false
      t.column "confirmed", :boolean, :default => true, :null => false
      t.column "parent_deal_id", :integer
      # foreign key (user_id) references users
    end

    # account_entries
    create_table("account_entries") do |t|
      t.column "user_id", :integer, :null => false
      t.column "account_id", :integer, :null => false
      t.column "deal_id", :integer, :null => false
      t.column "amount", :integer, :null => false
      t.column "balance", :integer
      t.column "friend_link_id", :integer
    end

    #account_rules
    create_table("account_rules") do |t|
      t.column "user_id", :integer, :null => false
      t.column "account_id", :integer, :null => false
      t.column "associated_account_id", :integer, :null => false
      t.column "closing_day", :integer, :default => 0, :null => false
      t.column "payment_term_months", :integer, :default => 1, :null => false
      t.column "payment_day", :integer, :default => 0, :null => false
    end

    #deal_links
    create_table("deal_links") do |t|
      t.column "created_user_id", :integer
    end
    
    #account_links
    create_table("account_links", :id => false) do |t|
      t.column "account_id", :integer, :null => false
      t.column "connected_account_id", :integer, :null => false
    end

    #preferences
    create_table("preferences") do |t|
      t.column "user_id", :integer, :null => false
      t.column "deals_scroll_height", :string, :limit => 20
      t.column "color", :string, :limit => 32
    end

  end

  def self.down
    drop_table "users"
    drop_table "friends"
    drop_table "accounts"
    drop_table "deals"
    drop_table "account_entries"
    drop_table "account_rules"
    drop_table "deal_links"
    drop_table "account_links"
    drop_table "preferences"

  end

end


