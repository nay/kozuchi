require 'time'

class Deal::Base < ApplicationRecord
  self.table_name = "deals"

  include Booking

  belongs_to :user

  # 実験的に読み出し専用の共通的なentryを設定
  has_many :readonly_entries, -> { order(:creditor, :line_number).includes(:account).readonly },
           class_name: "Entry::Base",
           foreign_key: 'deal_id'

  attr_writer :insert_before
  attr_accessor :old_date

  before_validation :update_date
  before_save :set_daily_seq
  before_save :touch_if_not_changed
  validates_presence_of :date
  
  scope :in_a_time_between, ->(from, to) { where("deals.date >= ? and deals.date <= ?", from, to) }
  scope :in_month, ->(year, month) {
    start_date = Date.new(year.to_i, month.to_i, 1)
    in_a_time_between(start_date, start_date.end_of_month)
  }
  scope :created_on, ->(date) { where("created_at >= ? and created_at < ?", date.beginning_of_day, (date + 1).beginning_of_day).order(created_at: :desc) }
  scope :time_ordering, -> { order(:date, :daily_seq) }
  scope :recently_updated_ordered, -> { order(updated_at: :desc) }
  scope :on, ->(account_or_account_id) {
    account_id = account_or_account_id.kind_of?(Account::Base) ? account_or_account_id.id : account_or_account_id
    where("account_entries.account_id = ?", account_id)
  }
  scope :confirmed, -> { where(confirmed: true) }

  def balance?
    false
  end

  def general?
    false
  end

  def human_name
    "記入 #{I18n.l(date)}-#{daily_seq}"
  end

  # 高速化のため、Castを経ないでDateを文字列として得られるメソッドを用意
  def date_as_str
    @attributes["date"]
  end

  def year
    split_date if !@year && self[:date]
    @year
  end  
  def month
    split_date if !@month && self[:date]
    @month
  end  
  def day
    split_date if !@day && self[:date]
    @day
  end
  
  def year=(year)
    self[:date] = nil
    @year = year
  end

  def month=(month)
    self[:date] = nil
    @month = month
  end

  def day=(day)
    self[:date] = nil
    @day = day
  end
  
  def split_date
    @year = self[:date] ? self[:date].year : nil
    @month = self[:date] ? self[:date].month : nil
    @day = self[:date] ? self[:date].day : nil
  end
  
  def date=(date)
    self[:date] = nil
    if date.kind_of?(Hash)
      @year = date[:year]
      @month = date[:month]
      @day = date[:day]
      update_date
    else
      self[:date] = date
      split_date
    end
  end
  
  def date
    update_date unless self[:date]
    self[:date]
  end
  
  def settlement_attached?
    false
  end

  def balance
    return nil
  end
  
  def self.get(deal_id, user_id)
    return Deal::Base.where("id = ? and user_id = ?", deal_id, user_id).first
  end

  def self.get_for_month(user_id, datebox)
    Deal::Base.where("deals.user_id = ? and date >= ? and date < ?",
                    user_id,
                    datebox.start_inclusive,
                    datebox.end_exclusive
    ).includes(:readonly_entries
    ).order(:date, :daily_seq)
  end

  # start_date から end_dateまでの、accounts に関連するデータを取得する。
  def self.get_for_accounts(user_id, start_date, end_date, accounts)
    raise "no user_id" unless user_id
    raise "no start_date" unless start_date
    raise "no end" unless end_date
    raise "no accounts" unless accounts
    Deal::Base.select("distinct dl.*"
    ).where("dl.user_id = ? and et.account_id in (?) and dl.date >= ? and dl.date < ?",
            user_id,
            accounts.map{|a| a.id},
            start_date,
            end_date + 1
    ).joins("as dl inner join account_entries as et on dl.id = et.deal_id"
    ).order("dl.date, dl.daily_seq")
  end
  
  def self.exists?(user_id, date)
    Deal::Base.select("dl.id"
    ).where("dl.user_id = ? and dl.date >= ? and dl.date < ?",
            user_id,
            date,
            date + 1
    ).joins("as dl inner join account_entries as et on dl.id = et.deal_id"
    ).exists?
  end

  def confirm!
    self.confirmed = true
    save!
  end

  # 記入対象の勘定のリスト（一意にしたもの）を返す
  def accounts
    readonly_entries.map(&:account).uniq
  end

  private

  def touch_if_not_changed
    touch unless changed?
  end
  
  # daily_seq をセットする。
  # super.before_save では呼び出せないためひとまずこの方式で。
  def set_daily_seq
    if new_record?
      self.daily_seq = nil
    else
      stored_self = Deal::Base.find(self.id)
      self.daily_seq = nil if self.date != stored_self.date
    end
  
    # 番号が入っていればそのまま
    return if self.daily_seq

    # 挿入先が指定されていれば挿入   
    if @insert_before
      # 日付が違ったら例外
      raise "An inserting point should be in the same date with the target." if @insert_before.date != self.date

      Deal::Base.connection.update(
        "update deals set daily_seq = daily_seq +1 where user_id = #{self.user_id} and date = '#{self.date.strftime('%Y-%m-%d')}' and ( daily_seq > #{@insert_before.daily_seq}  or (daily_seq = #{@insert_before.daily_seq} and id >= #{@insert_before.id}));"
      )
      self.daily_seq = @insert_before.daily_seq;

    # 挿入先が指定されていなければ新規
    else
      max = Deal::Base.where(["user_id = ? and date = ?",
                              self.user_id,
                              self.date]).maximum(:daily_seq) || 0
      self.daily_seq = 1 + max
    end
    
  end
  
  def update_date
    return if self[:date] # あるならそのまま
    
    begin
      self[:date] = Date.new(self.year.to_i, self.month.to_i, self.day.to_i) # TODO: year は 不正な文字でも 0年として登録される
    rescue
      self[:date] = nil
    end
  end
  


end
