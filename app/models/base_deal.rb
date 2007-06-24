require 'time'

class BaseDeal < ActiveRecord::Base
  set_table_name "deals"
  has_many   :account_entries,
             :foreign_key => 'deal_id',
             :exclusively_dependent => true,
             :order => "amount"

  belongs_to :user

  attr_writer :insert_before
  attr_accessor :old_date
  
  include ModelHelper
  
  before_save :set_daily_seq

  def settlement_attached?
    false
  end

  # entry に対するブロックを渡してもらい、条件に当てはまる entry の amount の合計を返す。
  def amount_if_entry
    entries = account_entries.select{|e| yield e}
    sum = 0
    entries.each{|e| sum += e.amount}
    sum
  end

  def subordinate?
    false
  end

  def parent_for(account_id)
    return nil
  end
  
  def child_for(account_id)
    return nil
  end
  
  def balance
    return nil
  end
  
  def self.get(deal_id, user_id)
    return BaseDeal.find(:first, :conditions => ["id = ? and user_id = ?", deal_id, user_id])
  end

  def self.get_for_month(user_id, datebox)
    BaseDeal.find(:all,
                  :conditions => [
                    "user_id = ? and date >= ? and date < ?",
                    user_id,
                    datebox.start_inclusive,
                    datebox.end_exclusive],
                  :order => "date, daily_seq")
  end

  def self.get_for_account(user_id, account_id, datebox)
    BaseDeal.find(:all,
                 :select => "dl.*",
                  :conditions => ["dl.user_id = ? and et.account_id = ? and dl.date >= ? and dl.date < ?",
                    user_id,
                    account_id,
                    datebox.start_inclusive,
                    datebox.end_exclusive],
                  :joins => "as dl inner join account_entries as et on dl.id = et.deal_id",
                  :order => "dl.date, dl.daily_seq"
    
    )
  end

  # start_date から end_dateまでの、accounts に関連するデータを取得する。
  def self.get_for_accounts(user_id, start_date, end_date, accounts)
    raise "no user_id" unless user_id
    raise "no start_date" unless start_date
    raise "no end" unless end_date
    raise "no accounts" unless accounts
    BaseDeal.find(:all,
                 :select => "distinct dl.*",
                  :conditions => ["dl.user_id = ? and et.account_id in (?) and dl.date >= ? and dl.date < ?",
                    user_id,
                    accounts.map{|a| a.id},
                    start_date,
                    end_date +1 ],
                  :joins => "as dl inner join account_entries as et on dl.id = et.deal_id",
                  :order => "dl.date, dl.daily_seq"
    )
  end
  
  def self.exists?(user_id, date)
    !BaseDeal.find(:first,
                 :select => "dl.id",
                  :conditions => ["dl.user_id = ? and dl.date >= ? and dl.date < ?",
                    user_id,
                    date,
                    date +1 ],
                  :joins => "as dl inner join account_entries as et on dl.id = et.deal_id"
    ).nil?
  end
  

  def set_old_date
    @old_date = self.date
  end
  
  def confirm
    BaseDeal.update_all("confirmed = #{boolean_to_s(true)}", "id = #{self.id}")
    # save にするとリンクまで影響がある。確定は単純に確定フラグだけを変えるべきなのでこのようにした。
  end


  protected
  # daily_seq をセットする。
  # super.before_save では呼び出せないためひとまずこの方式で。
  def set_daily_seq
    self.daily_seq = nil if self.date != @old_date
  
    # 番号が入っていればそのまま
    return if self.daily_seq

    # 挿入先が指定されていれば挿入   
    if @insert_before
      # 日付が違ったら例外
      raise "An inserting point should be in the same date with the target." if @insert_before.date != self.date

      Deal.connection.update(
        "update deals set daily_seq = daily_seq +1 where user_id = #{self.user_id} and date = '#{self.date.strftime('%Y-%m-%d')}' and ( daily_seq > #{@insert_before.daily_seq}  or (daily_seq = #{@insert_before.daily_seq} and id >= #{@insert_before.id}));"
      )
      self.daily_seq = @insert_before.daily_seq;

    # 挿入先が指定されていなければ新規
    else
      max = BaseDeal.maximum(:daily_seq,
        :conditions => ["user_id = ? and date = ?",
          self.user_id,
          self.date]
     ) || 0
      self.daily_seq = 1 + max

    end
    
  end

  
end