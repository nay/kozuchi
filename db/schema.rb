# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 14) do

  create_table "account_entries", :force => true do |t|
    t.integer "user_id",              :null => false
    t.integer "account_id",           :null => false
    t.integer "deal_id",              :null => false
    t.integer "amount",               :null => false
    t.integer "balance"
    t.integer "friend_link_id"
    t.integer "settlement_id"
    t.integer "result_settlement_id"
  end

  add_index "account_entries", ["account_id"], :name => "account_entries_account_id_index"
  add_index "account_entries", ["deal_id"], :name => "account_entries_deal_id_index"
  add_index "account_entries", ["user_id"], :name => "account_entries_user_id_index"
  add_index "account_entries", ["friend_link_id"], :name => "account_entries_friend_link_id_index"
  add_index "account_entries", ["settlement_id"], :name => "account_entries_settlement_id_index"
  add_index "account_entries", ["result_settlement_id"], :name => "account_entries_result_settlement_id_index"

  create_table "account_links", :id => false, :force => true do |t|
    t.integer "account_id",           :null => false
    t.integer "connected_account_id", :null => false
  end

  add_index "account_links", ["account_id"], :name => "account_links_account_id_index"
  add_index "account_links", ["connected_account_id"], :name => "account_links_connected_account_id_index"

  create_table "account_rules", :force => true do |t|
    t.integer "user_id",                              :null => false
    t.integer "account_id",                           :null => false
    t.integer "associated_account_id",                :null => false
    t.integer "closing_day",           :default => 0, :null => false
    t.integer "payment_term_months",   :default => 1, :null => false
    t.integer "payment_day",           :default => 0, :null => false
  end

  create_table "accounts", :force => true do |t|
    t.integer "user_id",                          :null => false
    t.string  "name",               :limit => 32, :null => false
    t.integer "account_type_code"
    t.integer "asset_type_code"
    t.integer "sort_key"
    t.integer "partner_account_id"
    t.text    "type"
  end

  add_index "accounts", ["user_id"], :name => "accounts_user_id_index"
  add_index "accounts", ["partner_account_id"], :name => "accounts_partner_account_id_index"

  create_table "admin_users", :force => true do |t|
    t.string "name"
    t.string "hashed_password", :limit => 40
  end

  create_table "deal_links", :force => true do |t|
    t.integer "created_user_id"
  end

  create_table "deals", :force => true do |t|
    t.string   "type",           :limit => 20,                   :null => false
    t.integer  "user_id",                                        :null => false
    t.date     "date",                                           :null => false
    t.integer  "daily_seq",                                      :null => false
    t.string   "summary",        :limit => 64,                   :null => false
    t.boolean  "confirmed",                    :default => true, :null => false
    t.integer  "parent_deal_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deals", ["user_id"], :name => "deals_user_id_index"
  add_index "deals", ["parent_deal_id"], :name => "deals_parent_deal_id_index"

  create_table "engine_schema_info", :id => false, :force => true do |t|
    t.string  "engine_name"
    t.integer "version"
  end

  create_table "friends", :force => true do |t|
    t.integer "user_id",                       :null => false
    t.integer "friend_user_id",                :null => false
    t.integer "friend_level",   :default => 1, :null => false
  end

  create_table "preferences", :force => true do |t|
    t.integer "user_id",                                              :null => false
    t.string  "deals_scroll_height", :limit => 20
    t.string  "color",               :limit => 32
    t.boolean "business_use",                      :default => false, :null => false
    t.boolean "use_daily_booking",                 :default => true,  :null => false
  end

  create_table "settlements", :force => true do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.text     "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.integer  "submitted_settlement_id"
    t.string   "type",                    :limit => 40
  end

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 80, :default => "", :null => false
    t.string   "email",                     :limit => 60, :default => "", :null => false
    t.string   "firstname",                 :limit => 40
    t.string   "lastname",                  :limit => 40
    t.string   "salt",                      :limit => 40, :default => "", :null => false
    t.string   "role",                      :limit => 40
    t.string   "activation_code",           :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "logged_in_at"
    t.string   "crypted_password",          :limit => 40
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.datetime "activated_at"
    t.string   "type",                      :limit => 40
    t.string   "password_token",            :limit => 40
    t.datetime "password_token_expires_at"
  end

end
