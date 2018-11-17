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

ActiveRecord::Schema.define(version: 2018_11_17_082413) do

  create_table "account_entries", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "account_id"
    t.integer "deal_id"
    t.integer "amount"
    t.integer "balance"
    t.integer "settlement_id"
    t.integer "result_settlement_id"
    t.boolean "initial_balance", default: false, null: false
    t.date "date", null: false
    t.integer "daily_seq", null: false
    t.integer "linked_ex_entry_id"
    t.integer "linked_ex_deal_id"
    t.integer "linked_user_id"
    t.string "type", limit: 20
    t.boolean "linked_ex_entry_confirmed", default: false, null: false
    t.string "summary", limit: 64, default: "", null: false
    t.boolean "creditor", default: false, null: false
    t.integer "line_number", default: 0, null: false
    t.boolean "confirmed", default: true, null: false
    t.index ["account_id"], name: "index_account_entries_on_account_id"
    t.index ["confirmed"], name: "index_account_entries_on_confirmed"
    t.index ["date", "daily_seq"], name: "index_account_entries_on_date_and_daily_seq"
    t.index ["deal_id", "creditor", "line_number"], name: "index_account_entries_on_deal_id_and_creditor_and_line_number", unique: true
    t.index ["deal_id"], name: "index_account_entries_on_deal_id"
    t.index ["initial_balance"], name: "index_account_entries_on_initial_balance"
    t.index ["result_settlement_id"], name: "index_account_entries_on_result_settlement_id"
    t.index ["settlement_id"], name: "index_account_entries_on_settlement_id"
    t.index ["type"], name: "index_account_entries_on_type"
    t.index ["user_id"], name: "index_account_entries_on_user_id"
  end

  create_table "account_link_requests", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "account_id"
    t.integer "sender_id"
    t.integer "sender_ex_account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
  end

  create_table "account_links", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "account_id"
    t.integer "target_user_id"
    t.integer "target_ex_account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["account_id"], name: "index_account_links_on_account_id"
    t.index ["target_ex_account_id"], name: "index_account_links_on_target_ex_account_id"
  end

  create_table "accounts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", limit: 32, null: false
    t.integer "sort_key"
    t.integer "partner_account_id"
    t.string "type", limit: 20
    t.string "asset_kind"
    t.boolean "active", default: true, null: false
    t.text "description"
    t.boolean "settlement_order_asc", default: true, null: false
    t.integer "settlement_paid_on", default: 31, null: false
    t.integer "settlement_closed_on_month", default: 1, null: false
    t.integer "settlement_closed_on_day", default: 31, null: false
    t.integer "settlement_target_account_id"
    t.integer "settlement_term_margin", default: 7, null: false
    t.index ["partner_account_id"], name: "index_accounts_on_partner_account_id"
    t.index ["type"], name: "index_accounts_on_type"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "deal_patterns", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "code", limit: 10, collation: "utf8_bin"
    t.string "name", default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "used_at"
    t.index ["user_id", "code"], name: "index_deal_patterns_on_user_id_and_code", unique: true
  end

  create_table "deals", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "type", limit: 20, null: false
    t.integer "user_id", null: false
    t.date "date", null: false
    t.integer "daily_seq", null: false
    t.string "old_summary", limit: 64, default: "", null: false
    t.boolean "confirmed", default: true, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_deals_on_user_id"
  end

  create_table "entry_patterns", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "deal_pattern_id", null: false
    t.boolean "creditor", default: false, null: false
    t.integer "line_number", null: false
    t.string "summary", default: "", null: false
    t.integer "account_id"
    t.integer "amount"
    t.index ["deal_pattern_id", "creditor", "line_number"], name: "creditor_line_number", unique: true
  end

  create_table "friend_permissions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "target_id"
    t.string "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "friend_requests", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "sender_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "preferences", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "color", limit: 32
    t.boolean "business_use", default: false, null: false
    t.boolean "use_daily_booking", default: true, null: false
    t.boolean "bookkeeping_style", default: false, null: false
  end

  create_table "sessions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data", limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "settlements", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "account_id"
    t.text "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
    t.integer "submitted_settlement_id"
    t.string "type", limit: 40
  end

  create_table "single_logins", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "login"
    t.string "crypted_password"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "login", limit: 80, default: "", null: false
    t.string "email", limit: 60, default: "", null: false
    t.string "salt", limit: 40, default: "", null: false
    t.string "role", limit: 40
    t.string "activation_code", limit: 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "logged_in_at"
    t.string "crypted_password", limit: 40
    t.string "remember_token"
    t.datetime "remember_token_expires_at"
    t.datetime "activated_at"
    t.string "type", limit: 40
    t.string "password_token", limit: 40
    t.datetime "password_token_expires_at"
  end

end
