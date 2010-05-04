class Settings::IncomesController < ApplicationController
  layout 'main'
  cache_sweeper :export_sweeper
  menu_group "設定"
  menu "収入内訳"

  before_filter :find_account, :only => [:destroy]

  # 一覧表示する。
  def index
    @accounts = current_user.incomes
    @account = Account::Income.new
  end

  # 新しい勘定を作成する。
  def create
    @account = current_user.incomes.build(params[:account])
    if @account.save
      flash[:notice]="「#{ERB::Util.h @account.name}」を登録しました。"
      redirect_to settings_incomes_path
    else
      @accounts = current_user.incomes(true)
      render :action => "index"
    end
  end

  def update_all
    raise InvalidParameterError unless params[:account]
    @accounts = []
    all_saved = true
    for id, attributes in params[:account] do
      account = current_user.incomes.find(id)
      all_saved = false unless account.update_attributes(attributes)
      @accounts << account
    end
    if all_saved
      flash[:notice] = "すべての#{Account::Income.human_name}を変更しました。"
      redirect_to settings_incomes_path
    else
      flash.now[:notice] = "変更できなかった#{Account::Income.human_name}があります。"
      @accounts.sort!{|a, b| a.sort_key.to_i <=> b.sort_key.to_i}
      @account = Account::Income.new
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
    redirect_to settings_incomes_path
  end

  private
  def find_account
    @account = current_user.incomes.find(params[:id])
  end

end
