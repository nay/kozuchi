# 精算（決済）処理のコントローラ
class SettlementsController < ApplicationController
  layout 'main'
  before_filter :load_user, :check_credit_account

  # 新しい精算口座を作る
  def new
    @settlement = Settlement.new
    @settlement.user_id = @user.id
    
  
    @start_date = Date.today << 1
    @start_date = Date.new(@start_date.year, @start_date.month, 1)
    @end_date = @start_date >> 1
    @end_date -= 1
    
    @deals = []
  end
  
  protected
  def check_credit_account
    accounts = @user.accounts.types_in(:credit, :credit_card)
    if accounts.empty?
      render :action => 'no_credit_account'
      return false
    end
  end

end
