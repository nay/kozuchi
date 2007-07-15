# 勘定の登録・削除・変更処理の規定クラスとなるコントローラ。
class Settings::AccountsController < ApplicationController
  layout 'main'
  include TermHelper
  
  before_filter :require_post, :only => [:create, :update]
  
  protected

  # 新しい勘定を作成する。
  # params['account']['name']:: 勘定名
  # params['account']['asset_name']:: (口座の場合だけ必要)口座種類名。class.asset_name でクラスに指定された日本語の名前が入る。
  # params['account']['sort_key']:: 並び順
  def create
    account_attributes = params[:account]
    raise "no params[:account]" unless account_attributes

    account_attributes = account_attributes.clone
    asset_name = account_attributes.delete(:asset_name)
    
    account = account_class(asset_name).new(account_attributes)
    account.user_id = @user.id # params に入っていたとしても上書きするのでいいかなぁ。
    if account.save
      @user.accounts(true)
      flash[:notice]="#{account.class.type_name}「#{account.name}」を登録しました。"
    else
      flash_validation_errors(account)
    end
    redirect_to_index    
  end
  
  # 指定された勘定を削除する。
  # params[:id]:: 口座ID
  def delete
    unless params[:id]
      flash[:notice] = "#{term self.account_type}が指定されていません。"
      return redirect_to_index
    end

    begin
      target_account = @user.accounts.find(params[:id])
    rescue ActiveRecord::RecordNotFound => err
      flash[:notice]="指定された#{term self.account_type}がみつかりません。"
      return redirect_to_index
    end

    begin
      @user.accounts.delete(target_account)
      flash[:notice]="#{term self.account_type}「#{target_account.name}」を削除しました。"
    rescue Account::UsedAccountException => err
      flash[:errors]= [err.message]
    end
    
    redirect_to_index
  end

  # 複数の勘定を同時に更新する。
  # params[:account][1][name]:: id 1 の勘定名
  # params[:account][1][asset_type]:: id 1 の種別（口座の場合のみ）
  # params[:account][1][sort_key]::　id 1 の並び順
  # * 好きな個数送ることができる。
  # * user_id が送られてきても無視する。
  # * ログインユーザーのものでない id の情報も無視する。
  def update
    begin
      @user.accounts.update_all_with(params[:account])
      flash[:notice]="すべての#{term self.account_type}を変更しました。"
    rescue Account::IllegalClassChangeException => err
      flash[:errors] = [err.message]
    end
    @user.accounts(true)
    
    redirect_to_index
  end
  
  # 一覧表示する。
  def index
    @account_type = account_type # symbol
    @accounts = @user.accounts(true).select{|a|a.type_in? account_type}
    render(:template => "settings/shared/accounts")
  end
  
  private
  def redirect_to_index
    redirect_to(:action => 'index')
  end

end
