class Settings::AccountsController < ApplicationController
  layout 'main'
  include TermHelper
  
  before_filter :require_post, :only => [:create]
  
  before_filter :load_user
  
  protected

  # 新しい勘定を作成する
  def create
    account = Account.new(params[:account])
    account.user_id = @user.id
    account.account_type_symbol = self.account_type
    if account.save
      @user.accounts(true)
      flash[:notice]="#{account.account_type_name} '#{account.name}' を登録しました。"
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
      Account.transaction do
        for account in @user.accounts
          next unless params[:account][account.id.to_s]
          account.attributes = (params[:account][account.id.to_s])
          account.save!
        end
      end
      flash[:notice]="すべての#{term self.account_type}を変更しました。"
    rescue => err
      flash[:notice]="#{term self.account_type}を変更できませんでした。"
    end
    @user.accounts(true)
    
    redirect_to_index
  end
  
  def index
    @account_type = self.account_type # symbol
    @accounts = @user.accounts.select{|a|a.account_type_symbol == account_type}
    render(:action => "../shared/accounts")
  end
  
  private
  def redirect_to_index
    redirect_to(:action => 'index')
  end

end
