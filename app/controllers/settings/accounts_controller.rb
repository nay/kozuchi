class Settings::AccountsController < ApplicationController
  layout 'main'
  
  # TODO: ここで直接呼ばれたくない。hide_actionsだと子孫からも呼べなくなる。routes.rbマターかなぁ。
  
  def create
    new_account = Account.new(params[:account])
    new_account.user_id = session[:user].id
    begin
      new_account.save!
      flash[:notice]="#{new_account.account_type_name} '#{new_account.name}' を登録しました。"
    rescue => err
      flash_validation_errors(new_account)
      flash_error(err.to_s) if new_account.errors.empty?
    end
    redirect_to(:action => 'index')
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
  
  protected
  def load_accounts(account_type)
    @account = Account.new
    @account.account_type = account_type
    @accounts = Account.find_all(session[:user].id, [@account.account_type])
    render(:action => "../accounts/accounts")
  end

end
