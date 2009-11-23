class Entry::Balance < Entry::Base
  belongs_to :deal,
             :class_name => 'Deal::Balance',
             :foreign_key => 'deal_id'


  named_scope :without_initial, :initial_balance => false
end
