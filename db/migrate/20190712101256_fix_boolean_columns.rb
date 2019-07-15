class FixBooleanColumns < ActiveRecord::Migration[5.2]
  def change
    # account_entries

    # t.index ["confirmed"], name: "index_account_entries_on_confirmed"
    remove_index  :account_entries, name: :index_account_entries_on_confirmed
    # t.index ["deal_id", "creditor", "line_number"], name: "index_account_entries_on_deal_id_and_creditor_and_line_number", unique: true
    remove_index  :account_entries, name: :index_account_entries_on_deal_id_and_creditor_and_line_number
    # t.index ["initial_balance"], name: "index_account_entries_on_initial_balance"
    remove_index  :account_entries, name: :index_account_entries_on_initial_balance

    # t.boolean "initial_balance", default: false, null: false
    rename_column :account_entries, :initial_balance, :initial_balance_i
    add_column    :account_entries, :initial_balance, :boolean, default: false, null: false

    # t.boolean "linked_ex_entry_confirmed", default: false, null: false
    rename_column :account_entries, :linked_ex_entry_confirmed, :linked_ex_entry_confirmed_i
    add_column    :account_entries, :linked_ex_entry_confirmed, :boolean, default: false, null: false

    # t.boolean "creditor", default: false, null: false
    rename_column :account_entries, :creditor, :creditor_i
    add_column    :account_entries, :creditor, :boolean, default: false, null: false

    # t.boolean "confirmed", default: true, null: false
    rename_column :account_entries, :confirmed, :confirmed_i
    add_column    :account_entries, :confirmed, :boolean, default: true, null: false

    reversible do |dir|
      dir.up do
        execute "UPDATE account_entries SET initial_balance = TRUE WHERE initial_balance_i = 1;"
        execute "UPDATE account_entries SET linked_ex_entry_confirmed = TRUE WHERE linked_ex_entry_confirmed_i = 1;"
        execute "UPDATE account_entries SET creditor = TRUE WHERE creditor_i = 1;"
        execute "UPDATE account_entries SET confirmed = FALSE WHERE confirmed_i = 0;"
      end
    end

    add_index     :account_entries, :confirmed
    add_index     :account_entries, [:deal_id, :creditor, :line_number], name: :account_entries_creditor_line_number, unique: true
    add_index     :account_entries, :initial_balance

    # accounts

    # t.boolean "active", default: true, null: false
    rename_column :accounts, :active, :active_i
    add_column    :accounts, :active, :boolean, default: true, null: false

    # t.boolean "settlement_order_asc", default: true, null: false
    rename_column :accounts, :settlement_order_asc, :settlement_order_asc_i
    add_column    :accounts, :settlement_order_asc, :boolean, default: true, null: false

    reversible do |dir|
      dir.up do
        execute "UPDATE accounts SET active = FALSE WHERE active_i = 0;"
        execute "UPDATE accounts SET settlement_order_asc = FALSE WHERE settlement_order_asc_i = 0;"
      end
    end

    # deals

    # t.boolean "confirmed", default: true, null: false
    rename_column :deals, :confirmed, :confirmed_i
    add_column    :deals, :confirmed, :boolean, default: true, null: false

    reversible do |dir|
      dir.up do
        execute "UPDATE deals SET confirmed = FALSE WHERE confirmed_i = 0;"
      end
    end

    # entry_patterns

    # t.index ["deal_pattern_id", "creditor", "line_number"], name: "creditor_line_number", unique: true
    remove_index  :entry_patterns, name: :creditor_line_number

    # t.boolean "creditor", default: false, null: false
    rename_column :entry_patterns, :creditor, :creditor_i
    add_column    :entry_patterns, :creditor, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        execute "UPDATE entry_patterns SET creditor = TRUE WHERE creditor_i = 1;"
      end
    end

    add_index     :entry_patterns, [:deal_pattern_id, :creditor, :line_number], name: :deal_patterns_creditor_line_number, unique: true

    # preferences

    # t.boolean "business_use", default: false, null: false
    rename_column :preferences, :business_use, :business_use_i
    add_column    :preferences, :business_use, :boolean, default: false, null: false

    # t.boolean "use_daily_booking", default: true, null: false
    rename_column :preferences, :use_daily_booking, :use_daily_booking_i
    add_column    :preferences, :use_daily_booking, :boolean, default: true, null: false

    # t.boolean "bookkeeping_style", default: false, null: false
    rename_column :preferences, :bookkeeping_style, :bookkeeping_style_i
    add_column    :preferences, :bookkeeping_style, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        execute "UPDATE preferences SET business_use = TRUE WHERE business_use_i = 1;"
        execute "UPDATE preferences SET use_daily_booking = FALSE WHERE use_daily_booking_i = 0;"
        execute "UPDATE preferences SET bookkeeping_style = TRUE WHERE bookkeeping_style_i = 1;"
      end
    end
  end
end
