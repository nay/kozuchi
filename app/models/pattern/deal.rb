# -*- encoding : utf-8 -*-
class Pattern::Deal < ActiveRecord::Base
  self.table_name = 'deal_patterns'
  
  with_options :class_name => "Pattern::Entry", :foreign_key => 'deal_pattern_id', :extend =>  ::Deal::EntriesAssociationExtension do |e|
    e.has_many :debtor_entries, :conditions => {:creditor => false}, :order => :line_number, :dependent => :destroy
    e.has_many :creditor_entries, :conditions => {:creditor => true}, :order => :line_number, :dependent => :destroy
  end
  include ::Deal
  # 読み出し専用の共通的なentry
  has_many :readonly_entries, :include => :account, :class_name => "Pattern::Entry", :foreign_key => 'deal_pattern_id', :order => 'line_number, creditor', :readonly => true

  attr_accessible :code, :name, :summary_mode, :summary, :debtor_entries_attributes, :creditor_entries_attributes

  before_validation :set_user_id_to_entries

  scope :recent, lambda { order('updated_at desc').limit(10) }

  def to_s
    "#{"#{code} " if code.present?}#{name.present? ? name : "*#{summary}"}"
  end

  def human_name
    "#{self.class.model_name.human}「#{to_s}」"
  end

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
