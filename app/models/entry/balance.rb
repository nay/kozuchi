class Entry::Balance < Entry::Base
  belongs_to :deal,
             :class_name => 'Deal::Balance',
             :foreign_key => 'deal_id'

end
