# 未保存の精算を表すモデル。登録時に利用する。
class SettlementSource
  include ActiveModel::Model
  include ActiveModel::AttributeMethods
  include ActiveModel::AttributeAssignment

  attr_accessor :account
  attr_accessor :start_date, :end_date # 精算対象となる取引の期間（必ず存在）

  attr_writer   :name            # 名前
  attr_accessor :description     # 説明
  attr_accessor :year, :month, :paid_on # 精算年（必ず存在）、精算月（必ず存在）、精算日付
  # TODO: paid_on は直接設定しないようにしたいが、prepare時の操作が理解できていない
  attr_accessor :target_account_id      # 精算を行う相手勘定（必ず存在）

  # checked はユーザーが画面上で「選択する」ことを確認した状態（不正なdeal_idが混じり得る情報）
  # selected はDB上存在し、かつユーザーが画面上で「選択する」ことを確認した状態
  attr_writer   :checked_deal_ids
  attr_reader :selected_deal_ids

  # 最初に作成するとき
  def self.prepare(account:, year:, month:)
    us = new(account: account, year: year.to_i, month: month.to_i)
    us.start_date, us.end_date = account.term_for_settlement_paid_on(Date.new(us.year, us.month, 1))
    us.paid_on = [Date.new(us.year, us.month, 1) + account.settlement_paid_on - 1, Date.new(us.year, us.month, 1).end_of_month].min
    us.target_account_id = account.settlement_target_account_id
    us.checked_deal_ids = us.deals.map(&:id)
    us
  end

  %w(start_date end_date).each do |attribute_name|
    class_eval <<-METHOD
      def #{attribute_name}=(_date)
        @#{attribute_name} = cast_date(_date)
      end
    METHOD
  end

  def attributes=(_attributes)
    @entries = nil
    @deals = nil
    assign_attributes(_attributes)
  end

  def paid_on=(_paid_on)
    case _paid_on
    when Hash, ActionController::Parameters
      # 画面からは day だけを送るのでその際は請求月の情報を足す
      _paid_on[:year] ||= year
      _paid_on[:month] ||= month
    end
    @paid_on = cast_date(_paid_on)
  end

  def refresh(_account = nil)
    _account ? self.account = _account : account.reload
    @ordering = nil
    @entries = nil
    @deals = nil
    @settlement = nil
  end

  def check_all_deals
    @checked_deal_ids = deals.map(&:id)
  end

  def remove_all_deals
    @checked_deal_ids = []
  end

  def deal_ids=(deal_ids)
    @checked_deal_ids = deal_ids.keys.map(&:to_i)
  end

  def entries
    @entries ||= Entry::General.includes(:deal => {:entries => :account}).where("deals.user_id = ? and account_entries.account_id = ? and deals.date >= ? and deals.date <= ? and account_entries.settlement_id is null and account_entries.result_settlement_id is null and account_entries.balance is null", account.user_id, account.id, start_date, end_date).order("deals.date #{ordering}, deals.daily_seq #{ordering}")
  end

  def deals
    @deals ||= entries.map(&:deal)
  end

  def name
    @name ||= "#{account.name} #{year}/#{"%02d" % month}"
  end

  def selected_deal_ids
    deals.map(&:id) & checked_deal_ids
  end

  def new_settlement
    Settlement.new(
                  name: name,
                  description: description,
                  user_id: account.user_id,
                  account: account,
                  result_date: paid_on,
                  result_partner_account_id: target_account_id,
                  deal_ids: selected_deal_ids
    )
  end

  private

  def checked_deal_ids
    @checked_deal_ids ||= []
  end

  def ordering
    @ordering ||= account.settlement_order_asc ? 'asc' : 'desc'
  end

  def cast_date(_date)
    case _date
    when Hash, ActionController::Parameters
      begin
        Date.new(_date[:year].to_i, _date[:month].to_i, _date[:day].to_i)
      rescue
        raise InvalidDateError, "「#{_date[:year]}/#{_date[:month]}/#{_date[:day]}」は不正な日付です。"
      end
    else
      _date
    end
  end
end
