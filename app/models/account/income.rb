class Account::Income < Account::Base
  type_order 3
  type_name '収入内訳'
  short_name '収入'
  connectable_type Account::Expense

  def self.types
    []
  end

end
