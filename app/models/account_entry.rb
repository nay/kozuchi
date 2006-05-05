class AccountEntry < ActiveRecord::Base
  belongs_to :deal,
             :class_name => 'BaseDeal',
             :foreign_key => 'deal_id'
  belongs_to :account
  validates_presence_of :amount
  attr_accessor :balance_estimated, :unknown_amount
  
  def self.delete(deal_id, user_id)
    delete_all(["deal_id = ? and user_id = ?", deal_id, user_id])
  end
  
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
    return balance_at_the_start_of(user_id, account_id, start_exclusive)
  end

  def self.balance_at_the_start_of(user_id, account_id, start_exclusive)
    # なぜかとれるのが Balance に。。。
  
    # 期限より前の最新の残高確認情報を取得する
    balance = AccountEntry.find(:first,
                      :conditions => ["et.user_id = ? and et.account_id = ? and dl.date < ? and et.balance is not null", user_id, account_id, start_exclusive],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id",
                      :order => "dl.date desc, dl.daily_seq")
    p "balance = #{balance}"
    # 期限より前に残高確認がない場合
    if !balance
      # 期限より後に残高確認があるか？
      balance = AccountEntry.find(:first,
                      :conditions => ["et.user_id = ? and et.account_id = ? and dl.date >= ? and et.balance is not null", user_id, account_id, start_exclusive],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id",
                      :order => "dl.date desc, dl.daily_seq")
    p "balance = #{balance}"
      # 期限より後にも残高確認がなければ、期限以前の異動合計を残高とする（初期残高０とみなす）。なければ０とする。
      if !balance
        return AccountEntry.sum("amount",
                      :conditions => ["et.user_id = ? and account_id = ? and dl.date < ? and dl.undecided = ?", user_id, account_id, start_exclusive, false],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                      ) || 0
      # 期限より後に残高確認があれば、期首から残高確認までの異動分をその残高から引いたものを期首残高とする
      else
      # なぜ entry じゃない？？
    p "balance = #{balance}"
    p "balance.date = #{balance.date}"
    p "balance.balance = #{balance.balance}"
    
        return balance.balance - (AccountEntry.sum("amount",
                      :conditions => ["et.user_id = ? and account_id = ? and dl.date >= ? and (dl.date < ? or (dl.date =? and dl.daily_seq < ?)) and dl.undecided = ?", user_id, account_id, start_exclusive, balance.date, balance.date, balance.daily_seq, false],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                       ) || 0)
      end
      
    # 期限より前の最新残高確認があれば、それ以降の異動合計と残高を足したものとする。
    else
      return balance.balance + (AccountEntry.sum("amount",
                             :conditions => ["et.user_id = ? and account_id = ? and dl.date < ? and (dl.date > ? or (dl.date =? and dl.daily_seq > ?)) and dl.undecided = ?", user_id, account_id, start_exclusive, balance.date, balance.date, balance.daily_seq, false],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                             ) || 0)
    end
  end

end
