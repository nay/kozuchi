class Settlement < ActiveRecord::Base
  belongs_to :account, :class_name => 'Account::Base', :foreign_key => 'account_id'

  has_many :target_entries,
           :class_name => 'AccountEntry',
           :foreign_key => 'settlement_id',
           :include => :deal,
           :order => 'deal.date, deal.daily_seq',
           :conditions => "settlement_result = 0"

  has_many :result_entries,
           :class_name => 'AccountEntry',
           :foreign_key => 'settlement_id',
           :include => :deal,
           :order => 'deal.date, deal.daily_seq',
           :conditions => "settlement_result = 1"
  
  
  protected
  def validate
    errors.add_to_base("精算対象取引が１つもありません")if self.target_entries.empty?
  end
  
  def after_save
    self.target_entries.each{|e| e.save!}
  end
  
end
