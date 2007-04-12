class Settings::AccountsController < ApplicationController
  layout 'main'
  include TermHelper
  
  before_filter :load_user
  
  protected

  # 新しい勘定を作成する
  def create
    return error_not_found unless request.post?
    account = @user.accounts.build(params[:account])
    if account.save
      flash[:notice]="#{account.account_type_name} '#{account.name}' を登録しました。"
    else
      flash_validation_errors(account)
    end
    redirect_to_index    
  end
  
  def delete
    account_type = params[:account_type].to_i
    account_type_name = Account.get_account_type_name(account_type)
    target_account = Account.find(:first, :conditions => "id = #{params[:id]} and user_id = #{session[:user].id}")
    if !target_account
      flash[:notice]="指定された#{account_type_name}がみつかりません。"
      redirect_to(:action => 'index')
      return
    end
    # 使われていたら消せない
    if AccountEntry.find(:first, :conditions => "account_id = #{target_account.id}")
      flash[:notice]="#{account_type_name} '#{target_account.name}' はすでに使われているため削除できません。"
      redirect_to(:action => 'index')
      return
    end
    begin
      target_account.destroy
      flash[:notice]="#{account_type_name} '#{target_account.name}' を削除しました。"
    rescue => err
      flash[:errors]= [err.message]
    end
    
    redirect_to(:action => 'index')
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
