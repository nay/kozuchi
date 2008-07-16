class Settlement < ActiveRecord::Base
  belongs_to :account, :class_name => 'Account::Base', :foreign_key => 'account_id'

  has_many :target_entries,
           :class_name => 'AccountEntry',
           :foreign_key => 'settlement_id',
           :order => 'deals.date, deals.daily_seq',
           :include => :deal,
           :dependent => :nullify

  has_one  :result_entry,
           :class_name => 'AccountEntry',
           :foreign_key => 'result_settlement_id',
           :include => :deal

  belongs_to :submitted_settlement
  
  belongs_to :user

  attr_accessor :result_date, :result_partner_account_id

  def target_sum
    sum = 0
    target_entries.each{|e| sum += e.amount}
    sum
  end
  
  # 相手に提出済にする
  def submit
    # すでに提出済ならエラー
    raise "すでに#{submitted_settlement.user.login}さんに提出されています。" if self.submitted_settlement
    
    target_account = account.connected_accounts.first # 1つであることを想定
    raise "#{account.name}には連携先がありません。" unless target_account

    submitted = nil
    Settlement.transaction do
      submitted = SubmittedSettlement.create!(:user_id => target_account.user_id, :account_id => target_account.id, :name => "#{account.name}の精算")
      # この精算にひもづいた entry に対応する entryを全部これにひもづける
      for e in target_entries
        # 本来あるはずのリンクがない（先方が故意に消したなど）場合は新しく作る
        e.create_friend_deal unless e.linked_account_entry
        submitted.target_entries << e.linked_account_entry
      end
      # この精算の result_entry のひもづけ
      raise "異常なデータです。精算取引がありません。" unless self.result_entry
      result_entry.create_friend_deal unless result_entry.linked_account_entry
      submitted.result_entry = result_entry.linked_account_entry
      
      self.submitted_settlement_id = submitted.id
      self.save!
    end
    
    submitted
  end
  
  def deletable?
    self.submitted_settlement_id.blank?
  end
    
  
  protected
  
  def validate
    errors.add_to_base("対象取引が１件もありません。") if self.target_entries.empty?
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
        :confirmed => true # false にすると、相手方の操作によって消されてしまう。リスク低減のためtrueにする      
      )
      result_deal.save!
      self.result_entry = result_deal.account_entries.detect{|e| e.account_id.to_s == self.account_id.to_s}
    end
    self.result_entry.save!
  end
  
  def before_destroy
    # submit されていたら消せない
    raise "提出済の精算データは削除できません。" if self.submitted_settlement_id
  end
  
  def after_destroy
    self.result_entry.deal.destroy if self.result_entry
  end
  
end
