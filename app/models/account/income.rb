class Account::Income < Account::Base
  type_order 3
  type_name '収入内訳'
  short_name '収入'
  connectable_type Account::Expense

  def base_type
    :income
  end
  def likable_to?(target_base_type)
    target_base_type == :expense
  end

  def self.types
    []
  end

end
