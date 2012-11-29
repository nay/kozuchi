# -*- encoding : utf-8 -*-
class Pattern::Deal < ActiveRecord::Base
  self.table_name = 'deal_patterns'
  attr_accessible :code, :name

  has_many :debtor_entries, :conditions => {:creditor => false}, :order => :line_number, :dependent => :destroy
  has_many :creditor_entries, :conditions => {:creditor => true}, :order => :line_number, :dependent => :destroy

  include ::Deal

  before_validation :set_user_id_to_entries

  private
  def set_user_id_to_entries
    debtor_entries.each do |e|
      e.user_id = user_id
    end
    creditor_entries.each do |e|
      e.user_id = user_id
    end
  end
end
