# 未保存の精算を表すモデル。登録時に利用する。
class UnsavedSettlement
  include ActiveModel::Model
  include ActiveModel::AttributeMethods

  attr_accessor :account
  attr_accessor :start_date, :end_date # 精算対象となる取引の期間（必ず存在）

  attr_writer   :name            # 名前
  attr_accessor :description     # 説明
  attr_accessor :year, :month, :paid_on # 精算年（必ず存在）、精算月（必ず存在）、精算日付
  attr_accessor :target_account_id      # 精算を行う相手勘定（必ず存在）

  %w(start_date end_date paid_on).each do |attribute_name|
    class_eval <<-METHOD
      def #{attribute_name}=(_date)
        @#{attribute_name} = cast_date(_date)
      end
    METHOD
  end

  def self.prepare(account:, year:, month:)
    us = new(account: account, year: year.to_i, month: month.to_i)

    us.start_date, us.end_date = account.term_for_settlement_paid_on(Date.new(year, month, 1))
    us.paid_on = [Date.new(year, month, 1) + account.settlement_paid_on - 1, Date.new(year, month, 1).end_of_month].min
    us.target_account_id = account.settlement_target_account_id
    us
  end

  def name
    @name ||= "#{account.name} #{year}/#{"%02d" % month}"
  end

  private
  def cast_date(_date)
    case _date
    when Hash
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
