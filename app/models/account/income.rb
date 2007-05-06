class Account::Expense < Account::Base
end
class Account::Income < Account::Base
  type_order 3
  type_name '収入内訳'
  short_name '収入'
  connectable_type Expense
end
