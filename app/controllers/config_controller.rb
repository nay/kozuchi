class ConfigController < ApplicationController
  before_filter :authorize
  layout "userview"
  
  def initialize
    @menu_items = {}
    @menu_items.store("assets", "口座")
    @menu_items.store("expenses", "費目")
    @menu_items.store("incomes", "収入内訳")
    @actions = {1 => "assets", 2 => "expenses", 3 => "incomes"}
  end
  
  def title
    "設定"
  end
  
  def name
    "config"
  end
  
  def menu_items
    @menu_items
  end

  def index
    redirect_to(:action => "assets")
  end
  
  def accounts
  end
  
  #資産口座の編集開始
  def assets
    #資産口座の一覧をロードする    
    load_accounts(1)
  end
  
  def expenses
    load_accounts(2)
  end

  def incomes
    load_accounts(3)
  end
  
  def load_accounts(account_type)
    @account = Account.new
    @account.account_type = account_type
    @accounts = Account.find_all(session[:user].id, [@account.account_type])
    render(:action => "accounts")
  end
  
  def create_account
    new_account = Account.new(params[:account])
    new_account.user_id = session[:user].id
    if new_account.save
      flash[:notice]="#{new_account.account_type_name} '#{new_account.name}' を登録しました。"
      p flash[:notice].to_s
    else
      flash[:notice]="#{new_account.account_type_name} '#{new_account.name}' を登録できませんでした。"
    end
    redirect_to(:action => @actions[new_account.account_type])
  end
  
  def delete_account
    account_type = params[:account_type].to_i
    account_type_name = Account.get_account_type_name(account_type)
    target_account = Account.find(:first, :conditions => "id = #{params[:id]} and user_id = #{session[:user].id}")
    if !target_account
      flash[:notice]="指定された#{account_type_name}がみつかりません。"
      redirect_to(:action => @actions[account_type])
      return
    end
    # 使われていたら消せない
    if AccountEntry.find(:first, :conditions => "account_id = #{target_account.id}")
      flash[:notice]="#{account_type_name} '#{target_account.name}' はすでに使われているため削除できません。"
      redirect_to(:action => @actions[account_type])
      return
    end
    flash[:notice]="#{account_type_name} '#{target_account.name}' を削除しました。"
    target_account.destroy
    redirect_to(:action => @actions[account_type])
  end
  
  def update_accounts
    account_type = params[:account_type].to_i
    account_type_name = Account.get_account_type_name(account_type)
    # todo 悪意ある post によってuser_id と一致しない危険性がちょっと気になる。
    Account.update(params[:account].keys, params[:account].values)
    flash[:notice]="すべての#{account_type_name}を変更しました。"
    redirect_to(:action => @actions[account_type])
  end
  
  
end
