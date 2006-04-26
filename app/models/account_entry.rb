class AccountEntry < ActiveRecord::Base
  belongs_to :deal
  belongs_to :account
  validates_presence_of :amount
  attr_accessor :balance_estimated
  
  def self.get_for_month(user_id, account_id, year, month)
    start_inclusive = Date.new(year, month, 1)
    end_exclusive = start_inclusive >> 1
    AccountEntry.find(:all, 
      :conditions => ["et.user_id = ? and account_id =? and dl.date >= ? and dl.date < ?", user_id, account_id, start_inclusive, end_exclusive],
      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
      )
#      ,
#      :order => "dl.date desc, dl.id desc")
  end
  
  def self.balance_start(user_id, account_id, year, month)
    start_exclusive = Date.new(year, month, 1)
    # 期限より前の最新の残高確認情報を取得する
    entry = AccountEntry.find(:first,
                      :conditions => ["et.user_id = ? and et.account_id = ? and dl.date < ? and et.balance is not null", user_id, account_id, start_exclusive],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id",
                      :order => "dl.date, dl.daily_seq")
    if !entry
      return AccountEntry.sum("amount",
                      :conditions => ["et.user_id = ? and account_id = ? and dl.date < ?", user_id, account_id, start_exclusive],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                      )
    else
      return entry.balance + AccountEntry.sum("amount",
                             :conditions => ["et.user_id = ? and account_id = ? and dl.date < ? and (dl.date > ? or (dl.date =? and dl.daily_seq > ?)", user_id, account_id, start_exclusive, entry.deal.date, entry.deal.date, entry.deal.daily_seq],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                             )
    end
                      
  end
end
