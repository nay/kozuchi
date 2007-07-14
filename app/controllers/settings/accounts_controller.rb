# 勘定の登録・削除・変更処理の規定クラスとなるコントローラ。
class Settings::AccountsController < ApplicationController
  layout 'main'
  include TermHelper
  
  before_filter :require_post, :only => [:create]
  
  before_filter :load_user
  
  protected

  # 新しい勘定を作成する
  def create
    if self.account_type == :asset
      account_class = Account::Asset.types.detect{|a| a.asset_name == params[:account][:type]}
      raise "Unknown account type #{params[:account][:type]} in #{Account::Asset.types}" unless account_class
    else
      account_class = self.account_type == :expense ? Account::Expense : Account::Income
    end
    account = account_class.new(params[:account])
    account.user_id = @user.id
    if account.save
      @user.accounts(true)
      flash[:notice]="#{account_class.type_name} '#{account.name}' を登録しました。"
    else
      flash_validation_errors(account)
    end
    redirect_to_index    
  end
  
  # 指定された勘定を削除する
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
      flash[:notice]="#{term self.account_type} '#{target_account.name}' を削除しました。"
    rescue => err
      flash[:errors]= [err.message]
    end
    
    redirect_to_index
  end

  # 複数の勘定を同時に更新する 
  def update
    # ユーザーIDに属する以外は無視する
    # (TODO: user_id が保護されていることを確認)
    begin
      Account::Base.transaction do
        for account in @user.accounts
          next unless params[:account][account.id.to_s]
          account.attributes = (params[:account][account.id.to_s])
          account.save!
        end
      end
      flash[:notice]="すべての#{term self.account_type}を変更しました。"
    rescue => err
      logger.error("Exception was raised when accounts were going to be updated.")
      logger.error(err)
      flash[:notice]="#{term self.account_type}を変更できませんでした。"
    end
    @user.accounts(true)
    
    redirect_to_index
  end
  
  def index
    @account_type = self.account_type # symbol
    @accounts = @user.accounts.select{|a|a.type_in? account_type}
    render(:template => "settings/shared/accounts")
  end
  
  private
  def redirect_to_index
    redirect_to(:action => 'index')
  end

end
