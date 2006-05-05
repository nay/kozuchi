require 'time'

class BaseDeal < ActiveRecord::Base
  set_table_name "deals"
  has_many :account_entries,
           :foreign_key => 'deal_id',
           :exclusively_dependent => true,
           :order => "amount"
  attr_writer :insert_before
  attr_accessor :old_date
  
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

  def set_old_date
    @old_date = self.date
  end

  # daily_seq ‚ğƒZƒbƒg‚·‚éB
  def before_save
    self.daily_seq = nil if self.date != @old_date
  
    # ”Ô†‚ª“ü‚Á‚Ä‚¢‚ê‚Î‚»‚Ì‚Ü‚Ü
    return if self.daily_seq

    # ‘}“üæ‚ªw’è‚³‚ê‚Ä‚¢‚ê‚Î‘}“ü   
    if @insert_before
      # “ú•t‚ªˆá‚Á‚½‚ç—áŠO
      raise "An inserting point should be in the same date with the target." if @insert_before.date != self.date

      Deal.connection.update(
        "update deals set daily_seq = daily_seq +1 where user_id == #{self.user_id} and date == '#{self.date.strftime('%Y-%m-%d')}' and ( daily_seq > #{insert_before.daily_seq}  or (daily_seq == #{insert_before.daily_seq} and id >= #{insert_before.id}));"
      )
      self.daily_seq = @insert_before.daily_seq;

    # ‘}“üæ‚ªw’è‚³‚ê‚Ä‚¢‚È‚¯‚ê‚ÎV‹K
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