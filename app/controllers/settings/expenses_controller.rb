class Settings::ExpensesController < ApplicationController
  layout 'main'
  cache_sweeper :export_sweeper
  menu_group "設定"
  menu "費目"

  before_filter :find_account, :only => [:destroy]

  # 一覧表示する。
  def index
    @accounts = current_user.expenses
    @account = Account::Expense.new
  end

  # 新しい勘定を作成する。
  def create
    @account = current_user.expenses.build(params[:account])
    if @account.save
      flash[:notice] = "「#{ERB::Util.h @account.name}」を登録しました。"
      redirect_to settings_expenses_path
    else
      @accounts = current_user.expenses(true)
      render :action => "index"
    end
  end

  def update_all
    raise InvalidParameterError unless params[:account]
    @accounts = []
    all_saved = true
    for id, attributes in params[:account] do
      account = current_user.expenses.find(id)
      all_saved = false unless account.update_attributes(attributes)
      @accounts << account
    end
    if all_saved
      flash[:notice] = "すべての#{Account::Expense.human_name}を変更しました。"
      redirect_to settings_expenses_path
    else
      flash[:notice] = "変更できなかった#{Account::Expense.human_name}があります。"
      @accounts.sort!{|a, b| a.sort_key.to_i <=> b.sort_key.to_i}
      @account = Account::Expense.new
      render :action => "index"
    end
  end

  def destroy
    begin
      @account.destroy
      flash[:notice]="「#{ERB::Util.h @account.name}」を削除しました。"
    rescue Account::Base::UsedAccountException => err
      flash[:errors]= [err.message]
    end
    redirect_to settings_expenses_path
  end

  private
  def find_account
    @account = current_user.expenses.find(params[:id])
  end
  
end
