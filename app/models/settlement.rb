class Settlement < ActiveRecord::Base
  belongs_to :account, :class_name => 'Account::Base', :foreign_key => 'account_id'

  has_many :target_entries,
           :class_name => 'AccountEntry',
           :foreign_key => 'settlement_id',
           :include => :deal,
           :order => 'deals.date, deals.daily_seq',
           :dependent => :nullify

  has_one  :result_entry,
           :class_name => 'AccountEntry',
           :foreign_key => 'result_settlement_id',
           :include => :deal

  attr_accessor :result_date, :result_partner_account_id

  def target_sum
    sum = 0
    target_entries.each{|e| sum += e.amount}
    sum
  end
  
  protected
  
  def validate
    errors.add_to_base("精算対象取引が１つもありません")if self.target_entries.empty?
  end
  
  def after_save
    self.target_entries.each{|e| e.save!}
    if !self.result_entry && self.result_partner_account_id && self.result_date
      amount = 0
      target_entries.each{|e| amount -= e.amount}
      # account への出し入れの逆の金額が来る
      # 精算取引の金額がマイナスなら、accountから引くということ
      if amount < 0
        minus_account_id = self.account_id
        plus_account_id = self.result_partner_account_id
      else
        plus_account_id = self.account_id
        minus_account_id = self.result_partner_account_id
      end
      result_deal = Deal.new(
        :minus_account_id => minus_account_id,
        :plus_account_id => plus_account_id,
        :amount => amount.abs,
        :user_id => self.user_id,
        :date => self.result_date,
        :summary => self.name,
        :confirmed => false      
      )
      result_deal.save!
      self.result_entry = result_deal.account_entries.detect{|e| e.account_id.to_s == self.account_id.to_s}
    end
    self.result_entry.save!
  end
  
  def before_destroy
    self.result_entry.deal.destroy
  end
  
end
