# 未保存の精算を表すモデル。登録時に利用する。
class UnsavedSettlement
  include ActiveModel::Model
  include ActiveModel::AttributeMethods

  attr_accessor :start_date, :end_date # 精算対象となる取引の期間（必ず存在）

  attr_accessor :name, :description     # 名前、説明
  attr_accessor :year, :month, :paid_on # 精算年（必ず存在）、精算月（必ず存在）、精算日付
  attr_accessor :target_account_id      # 精算を行う相手勘定（必ず存在）

  %(start_date end_date paid_on).each do |attribute_name|
    class_eval <<-METHOD
      def #{attribute_name}=(_date)
        @#{attribute_name} = cast_date(_date)
      end
    METHOD
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
