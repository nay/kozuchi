class Entry::General < Entry::Base
  belongs_to :deal,
             :class_name => 'Deal::General',
             :foreign_key => 'deal_id'
  belongs_to :settlement
  belongs_to :result_settlement, :class_name => 'Settlement', :foreign_key => 'result_settlement_id'

  before_destroy :assert_no_settlement

end
