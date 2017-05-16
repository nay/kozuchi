# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170516212531) do

  create_table "account_entries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "account_id"
    t.integer "deal_id"
    t.integer "amount"
    t.integer "balance"
    t.integer "settlement_id"
    t.integer "result_settlement_id"
    t.boolean "initial_balance",                      default: false, null: false
    t.date    "date",                                                 null: false
    t.integer "daily_seq",                                            null: false
    t.integer "linked_ex_entry_id"
    t.integer "linked_ex_deal_id"
    t.integer "linked_user_id"
    t.string  "type"
    t.boolean "linked_ex_entry_confirmed",            default: false, null: false
    t.string  "summary",                   limit: 64, default: "",    null: false
    t.boolean "creditor",                             default: false, null: false
    t.integer "line_number",                          default: 0,     null: false
    t.boolean "confirmed",                            default: true,  null: false
    t.index ["account_id"], name: "index_account_entries_on_account_id", using: :btree
    t.index ["confirmed"], name: "index_account_entries_on_confirmed", using: :btree
    t.index ["date", "daily_seq"], name: "index_account_entries_on_date_and_daily_seq", using: :btree
    t.index ["deal_id", "creditor", "line_number"], name: "index_account_entries_on_deal_id_and_creditor_and_line_number", unique: true, using: :btree
    t.index ["deal_id"], name: "index_account_entries_on_deal_id", using: :btree
    t.index ["initial_balance"], name: "index_account_entries_on_initial_balance", using: :btree
    t.index ["result_settlement_id"], name: "index_account_entries_on_result_settlement_id", using: :btree
    t.index ["settlement_id"], name: "index_account_entries_on_settlement_id", using: :btree
    t.index ["user_id"], name: "index_account_entries_on_user_id", using: :btree
  end

  create_table "account_link_requests", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "account_id"
    t.integer  "sender_id"
    t.integer  "sender_ex_account_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "user_id"
  end

  create_table "account_links", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.integer  "target_user_id"
    t.integer  "target_ex_account_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.index ["account_id"], name: "index_account_links_on_account_id", using: :btree
    t.index ["target_ex_account_id"], name: "index_account_links_on_target_ex_account_id", using: :btree
  end

  create_table "accounts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id",                                           null: false
    t.string  "name",                 limit: 32,                   null: false
    t.integer "sort_key"
    t.integer "partner_account_id"
    t.text    "type",                 limit: 65535
    t.string  "asset_kind"
    t.boolean "active",                             default: true, null: false
    t.text    "description",          limit: 65535
    t.boolean "settlement_order_asc",               default: true, null: false
    t.index ["partner_account_id"], name: "index_accounts_on_partner_account_id", using: :btree
    t.index ["user_id"], name: "index_accounts_on_user_id", using: :btree
  end

  create_table "deal_patterns", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "user_id",                            null: false
    t.string   "code",       limit: 10,                           collation: "utf8_bin"
    t.string   "name",                  default: "", null: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.datetime "used_at"
    t.index ["user_id", "code"], name: "index_deal_patterns_on_user_id_and_code", unique: true, using: :btree
  end

  create_table "deals", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "type",        limit: 20,                null: false
    t.integer  "user_id",                               null: false
    t.date     "date",                                  null: false
    t.integer  "daily_seq",                             null: false
    t.string   "old_summary", limit: 64, default: "",   null: false
    t.boolean  "confirmed",              default: true, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_deals_on_user_id", using: :btree
  end

  create_table "entry_patterns", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id",                         null: false
    t.integer "deal_pattern_id",                 null: false
    t.boolean "creditor",        default: false, null: false
    t.integer "line_number",                     null: false
    t.string  "summary",         default: "",    null: false
    t.integer "account_id"
    t.integer "amount"
    t.index ["deal_pattern_id", "creditor", "line_number"], name: "creditor_line_number", unique: true, using: :btree
  end

  create_table "friend_permissions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "user_id"
    t.integer  "target_id"
    t.string   "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "friend_requests", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "user_id"
    t.integer  "sender_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "preferences", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "user_id",                                      null: false
    t.string  "color",             limit: 32
    t.boolean "business_use",                 default: false, null: false
    t.boolean "use_daily_booking",            default: true,  null: false
    t.boolean "bookkeeping_style",            default: false, null: false
  end

  create_table "sessions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "session_id",               null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", using: :btree
    t.index ["updated_at"], name: "index_sessions_on_updated_at", using: :btree
  end

  create_table "settlements", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.text     "name",                    limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description",             limit: 65535
    t.integer  "submitted_settlement_id"
    t.string   "type",                    limit: 40
  end

  create_table "single_logins", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "login"
    t.string   "crypted_password"
    t.integer  "user_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "login",                     limit: 80, default: "", null: false
    t.string   "email",                     limit: 60, default: "", null: false
    t.string   "salt",                      limit: 40, default: "", null: false
    t.string   "role",                      limit: 40
    t.string   "activation_code",           limit: 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "logged_in_at"
    t.string   "crypted_password",          limit: 40
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.datetime "activated_at"
    t.string   "type",                      limit: 40
    t.string   "password_token",            limit: 40
    t.datetime "password_token_expires_at"
  end

end
