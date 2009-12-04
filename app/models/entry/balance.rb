class Entry::Balance < Entry::Base
  belongs_to :deal,
             :class_name => 'Deal::Balance',
             :foreign_key => 'deal_id'


  named_scope :without_initial, :conditions => {:initial_balance => false}
end
