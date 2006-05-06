class AccountRule < ActiveRecord::Base
  belongs_to :associated_account,
             :class_name => 'Account',
             :foreign_key => 'associated_account_id'
  belongs_to :account

  # 元となる取引に対して、精算予定日を計算する
  def payment_date(date)
    # この取引の締月を計算する。日にちは1で計算する。
    closing_date = Date.new(date.year, date.month, 1)
    # 過ぎていたら来月
    if (closing_day != 0 && closing_day < date.day)
      closing_date = closing_date >> 1
    end
  
    # 締月から精算月を計算する
    payment_date = closing_date >> self.payment_term_months

    # 精算日を入れて返す
    self.payment_day == 0 ? last_day(payment_date.year, payment_date.month) : Date.new(payment_date.year, payment_date.month, self.payment_day)
  end
  
  # 末日を求める（わからんので。。）
  def last_day(year, month)
    date = (Date.new(year, month, 1) >> 1)-1
  end
  
  def self.find_all(user_id)
    return find(:all, :conditions => ['user_id = ?', user_id])
  end
  
  def self.get(user_id, id)
    return find(:first, :conditions => ["user_id = ? and id = ?", user_id, id])
  end
  
  def self.find_associated_with(associated_account_id)
    return find(:all, :conditions => ["associated_account_id = ?", associated_account_id])
  end
  
  def self.find_binded_with(binded_account_id)
    return find(:all, :conditions => ["account_id = ?", binded_account_id])
  end


  def validate
    # 支払い月が当月の場合は、締め日＜＝支払日である必要がある。
    if self.payment_term_months == 0
      errors.add(:payment_day, "当月に精算する場合は、締日以降の精算日を指定してください。") unless (closing_day != 0 && self.closing_day <= payment_day ) || payment_day == 0
    end
  end

  
end
