class Account::Expense < Account::Base
  type_order 2
  type_name '費目'
  short_name '支出'
  connectable_type Account::Income

  def expense?
    true
  end

  # TODO: Rails 2.2
  def self.human_name
    '費目'
  end

  def base_type
    :expense
  end
  def linkable_to?(target_base_type)
    target_base_type == :income
  end

  def self.types
    []
  end

  # 指定したユーザー、期間の支出合計額（不明金を換算しない）を得る
  def self.raw_sum_of(user_id, start_date, end_date)

    # 支出項目の残高の合計を得る - 月初から月末までのAccountEntryのamount合計を得る。
    Entry::Base.joins("inner join accounts on account_entries.account_id = accounts.id inner join deals on deals.id = account_entries.deal_id").where("account_entries.user_id = ? and accounts.type = 'Account::Expense' and deals.date >= ? and deals.date < ?", user_id, start_date, end_date).sum(:amount) || 0
  end

end
