class DailyBookingController < ApplicationController

  before_filter :load_user, :check_use, :load_account
  before_filter :load_menues

  def index
    begin
      @date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
    rescue
      @date = Date.today
    end

    @balance_at_the_start = @account.balance_before(@date)
    
    # 基準日での基準口座の残高を計算する
    @balance_at_the_end = @account.balance_before(@date + 1)
    
    # 基準日の関係ある取引を抽出する
    @deals = @user.deals(@date, @date, @user.accounts.types_in(:income, :expense) << @account)
    
    # 取引の中の収入、支出を集計する
    @total_income = 0
    @deals.each{|d| @total_income += d.amount_if_entry{|e| e.account.account_type_symbol == :income}}
    @total_income *= -1
    @total_expense = 0
    @deals.each{|d| @total_expense += d.amount_if_entry{|e| e.account.account_type_symbol == :expense}}

    # 編集の準備
    @deal = Deal.new
  end


  protected
  def check_use
    return not_found unless @user.preferences.use_daily_booking?
  end
  
  def load_account
    @account = Account.find_default_asset(@user.id)
    unless @account
      render(:template => 'daily_booking/no_account')
      return false
    end
  end


end
