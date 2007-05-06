class Account::Income < Account::Base
end
class Account::Expense < Account::Base
  type_order 2
  type_name '費目'
  short_name '支出'
  connectable_type Income
end
