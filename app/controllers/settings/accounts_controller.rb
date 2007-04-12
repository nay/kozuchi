class Settings::AccountsController < ApplicationController
  layout 'main'
  
  before_filter :load_user
  
  protected

  def create
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
  
  def update
    account_type = params[:account_type].to_i
    account_type_name = Account.get_account_type_name(account_type)
    # todo 悪意ある post によってuser_id と一致しない危険性がちょっと気になる。
    p params[:account].keys.to_s
    p params[:account].values.to_s
    Account.update(params[:account].keys, params[:account].values)
    flash[:notice]="すべての#{account_type_name}を変更しました。"
    
    redirect_to(:action => 'index')
  end
  
  def load_accounts(account_type)
    @account = Account.new
    @account.account_type = account_type
    @accounts = Account.find_all(session[:user].id, [@account.account_type])
    render(:action => "../accounts/accounts")
  end
  
  private
  def redirect_to_index
    redirect_to(:action => 'index')
  end

end
