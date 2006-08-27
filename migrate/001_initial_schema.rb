class InitialSchema < ActiveRecord::Migration
  def self.up
    create_table("account_entries") do |t|
      t.column "user_id", :integer, :null => false
      t.column "account_id", :integer, :null => false
      t.column "deal_id", :integer, :null => false
      t.column "amount", :integer, :null => false
      t.column "balance", :integer
      t.column "friend_link_id", :integer
    end

    create_table("account_rules") do |t|
      t.column "user_id", :integer, :null => false
      t.column "account_id", :integer, :null => false
      t.column "associated_account_id", :integer, :null => false
      t.column "closing_day", :integer, :default => 0, :null => false
      t.column "payment_term_months", :integer, :default => 1, :null => false
      t.column "payment_day", :integer, :default => 0, :null => false
    end

    create_table("accounts") do |t|
      t.column "user_id", :integer, :null => false
      t.column "name", :string, :limit => 32, :null => false
      t.column "account_type", :integer, :null => false
      t.column "asset_type", :integer
      t.column "sort_key", :integer
      t.column "partner_account_id", :integer
    end

    create_table("deal_links") do |t|
      t.column "created_user_id", :integer
    end

    create_table("deals") do |t|
      t.column "type", :string, :limit => 20, :null => false
      t.column "user_id", :integer, :null => false
      t.column "date", :date, :null => false
      t.column "daily_seq", :integer, :null => false
      t.column "summary", :string, :limit => 64, :null => false
      t.column "confirmed", :boolean, :default => true, :null => false
      t.column "parent_deal_id", :integer
    end

    create_table("friends") do |t|
      t.column "user_id", :integer, :null => false
      t.column "friend_user_id", :integer, :null => false
      t.column "friend_level", :integer, :default => 1, :null => false
    end

    create_table("preferences") do |t|
      t.column "user_id", :integer, :null => false
      t.column "deals_scroll_height", :string, :limit => 20
    end

    create_table("users") do |t|
      t.column "login_id", :string, :limit => 16, :null => false
      t.column "hashed_password", :string, :limit => 40, :null => false
    end

    add_index "users", ["login_id"], :name => "users_login_id", :unique => true
  end

  def self.down
    drop_table "account_entries"
    drop_table "account_rules"
    drop_table "accounts"
    drop_table "deal_links"
    drop_table "deals"
    drop_table "friends"
    drop_table "preferences"
    drop_table "users"
  end
end


