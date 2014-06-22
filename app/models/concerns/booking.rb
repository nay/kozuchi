# booking, Entry などを画面から「一行のデータ」として扱うためのモジュール
module Booking
  extend ActiveSupport::Concern

  # ある月の日ナビゲーターに必要なアンカー情報を渡されたリストに仕込むユーティリティメソッド
  def self.set_anchor_dates_to(bookings, year, month)
    date = Date.new(year.to_i, month.to_i, 1)
    bookings.each do |booking|
      # その記入以前のまだアンカー登録されていない日を抱えさせる
      while date <= booking.date
        booking.anchor_dates << date
        date += 1
      end
      # 後ろがなければ終わりも抱える
      if bookings.last == booking
        while date.month == booking.date.month
          booking.anchor_dates << date
          date += 1
        end
      end
    end
  end

  def anchor_dates
    @anchor_dates ||= []
    @anchor_dates
  end

end