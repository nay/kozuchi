class Account::Income < Account::Base
  type_order 3
  type_name '収入内訳'
  short_name '収入'
  connectable_type Account::Expense

  def income?
    true
  end

  # TODO: Rails 2.2 で国際化対応
  def self.human_name
    '収入内訳'
  end

  def base_type
    :income
  end
  def linkable_to?(target_base_type)
    target_base_type == :expense
  end

  def self.types
    []
  end

end
