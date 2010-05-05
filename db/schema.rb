# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100505211320) do

  create_table "account_entries", :force => true do |t|
    t.integer "user_id",                   :default => 0
    t.integer "account_id",                :default => 0
    t.integer "deal_id",                   :default => 0
    t.integer "amount"
    t.integer "balance"
    t.integer "settlement_id"
    t.integer "result_settlement_id"
    t.boolean "initial_balance",           :default => false, :null => false
    t.date    "date",                                         :null => false
    t.integer "daily_seq",                                    :null => false
    t.integer "linked_ex_entry_id"
    t.integer "linked_ex_deal_id"
    t.integer "linked_user_id"
    t.string  "type"
    t.boolean "linked_ex_entry_confirmed", :default => false, :null => false
  end

  add_index "account_entries", ["account_id"], :name => "account_entries_account_id_index"
  add_index "account_entries", ["deal_id"], :name => "account_entries_deal_id_index"
  add_index "account_entries", ["result_settlement_id"], :name => "account_entries_result_settlement_id_index"
  add_index "account_entries", ["settlement_id"], :name => "account_entries_settlement_id_index"
  add_index "account_entries", ["user_id"], :name => "account_entries_user_id_index"

  create_table "account_link_requests", :force => true do |t|
    t.integer  "account_id"
    t.integer  "sender_id"
    t.integer  "sender_ex_account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "account_links", :force => true do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.integer  "target_user_id"
    t.integer  "target_ex_account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "account_links", ["account_id"], :name => "index_account_links_on_account_id"
  add_index "account_links", ["target_ex_account_id"], :name => "index_account_links_on_target_ex_account_id"

  create_table "accounts", :force => true do |t|
    t.integer "user_id",                          :default => 0,  :null => false
    t.string  "name",               :limit => 32, :default => "", :null => false
    t.integer "sort_key"
    t.integer "partner_account_id"
    t.text    "type"
    t.string  "asset_kind"
  end

  add_index "accounts", ["partner_account_id"], :name => "accounts_partner_account_id_index"
  add_index "accounts", ["user_id"], :name => "accounts_user_id_index"

  create_table "deals", :force => true do |t|
    t.string   "type",       :limit => 20, :default => "",   :null => false
    t.integer  "user_id",                  :default => 0,    :null => false
    t.date     "date",                                       :null => false
    t.integer  "daily_seq",                :default => 0,    :null => false
    t.string   "summary",    :limit => 64, :default => "",   :null => false
    t.boolean  "confirmed",                :default => true, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deals", ["user_id"], :name => "deals_user_id_index"

  create_table "engine_schema_info", :id => false, :force => true do |t|
    t.string  "engine_name"
    t.integer "version"
  end

  create_table "friend_permissions", :force => true do |t|
    t.integer  "user_id"
    t.integer  "target_id"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "friend_requests", :force => true do |t|
    t.integer  "user_id"
    t.integer  "sender_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "preferences", :force => true do |t|
    t.integer "user_id",                           :default => 0,     :null => false
    t.string  "deals_scroll_height", :limit => 20
    t.string  "color",               :limit => 32
    t.boolean "business_use",                      :default => false, :null => false
    t.boolean "use_daily_booking",                 :default => true,  :null => false
    t.boolean "bookkeeping_style",                 :default => false, :null => false
    t.boolean "uses_complex_deal",                 :default => false, :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

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

  create_table "single_logins", :force => true do |t|
    t.string   "login"
    t.string   "crypted_password"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 80, :default => "", :null => false
    t.string   "email",                     :limit => 60, :default => "", :null => false
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
    t.string   "mobile_identity",           :limit => 40
  end

end
