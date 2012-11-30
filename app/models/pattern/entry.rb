# -*- encoding : utf-8 -*-
class Pattern::Entry < ActiveRecord::Base
  self.table_name = 'entry_patterns'

  include ::Entry
  attr_accessible :account_id, :amount, :line_number, :summary, :reversed_amount

end
