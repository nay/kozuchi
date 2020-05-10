class Entry::Balance < Entry::Base
  belongs_to :deal,
             :class_name => 'Deal::Balance',
             :foreign_key => 'deal_id'


  scope :without_initial, -> { where(initial_balance: false) }

  validates :balance, :presence => true, :numericality => {:only_integer => true, :allow_blank => true}

  # amountが変わるような更新はされない（作り直しになる）想定
  before_create :set_amount

  # システム内の全残高の含み損益を再計算して更新する
  def self.adjust_all!
    entries_per_user = where(initial_balance: false).order("date, daily_seq").includes(:deal).group_by(&:user_id)
    entries_per_user.each do |user_id, entries|
      next if entries.empty?
      Rails.logger.info "Start adjustment for User #{user_id}. entries: #{entries.size}  acounts: #{entries.group_by(&:account_id).keys}"
      begin
        transaction do
          entries.each do |e|
            e.deal.update_amount
          end
        end
      rescue Exception => e
        Rails.logger.error "Adjustment Error in User #{user_id}: #{e} #{e.backtrace.join("\n")}"
      end
    end
    true
  end

  def balance=(a)
    self[:balance] = self.class.parse_amount(a)
  end

  def summary
    initial_balance? ? '残高確認（初回）' : '残高確認'
  end

  def partner_account_name
    initial_balance? ? '' : '不明金'
  end

  def reversed_amount
    self.amount.blank? ? self.amount : self.amount.to_i * -1
  end

  # この残高記入直前の残高を求める
  def balance_before(ignore_initial = false)
    raise "date or daily_seq is nil!" unless self.date && self.daily_seq
    account.balance_before(date, daily_seq, ignore_initial)
  end

  private

  def set_amount
    current_initial_balance = self.class.includes(:deal).find_by(account_id: account_id ,initial_balance: true)
    this_will_be_initial = !current_initial_balance || current_initial_balance.deal.date > self.date || (current_initial_balance.deal.date == self.date && current_initial_balance.deal.daily_seq > self.daily_seq)
    self.amount = balance - balance_before(this_will_be_initial)
  end

end
