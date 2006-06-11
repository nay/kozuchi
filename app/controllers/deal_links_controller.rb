# 取引連動設定のコントローラ
class DealLinksController < ConfigController

  # 取引連動初期表示画面
  def index
    @accounts = Account.find_all(user.id, [Account::ACCOUNT_ASSET, Account::ACCOUNT_EXPENSE, Account::ACCOUNT_INCOME])
    @friends = user.interactive_friends(1)
    @accounts_with_partners = []
    for account in @accounts
      @accounts_with_partners << account unless account.connected_accounts.empty? && account.associated_accounts.empty?
    end
  end

  # 連動設定の追加
  def connect_account
    account_id = @params[:account] ? @params[:account][:id] : nil
    raise "no account_id" unless account_id
    
    account = Account.get(user.id, account_id)
    raise "no account" unless account
    
    friend_user_login_id = params[:account][:partner_login_id]
    target_account_name = params[:account][:partner_account_name]
    if !target_account_name || target_account_name == ""
      flash_error("フレンドの口座名を指定してください")
      redirect_to(:action => 'index')
      return
    end
    interactive = params[:account][:interactive] == 'true'

    begin  
      account.connect(friend_user_login_id, target_account_name, interactive)
    rescue => err
      if account.errors.empty?
        flash_error(err)
        flash_error(err.backtrace.to_s)
      else
        flash_validation_errors(account)
      end
    end
    redirect_to(:action => 'index')
  end

  # 連動設定の解除  
  def clear_connection
    account = Account.get(user.id, params[:id])
    raise "no account" if !account
    
    connected_account = Account.find(params[:connected_account_id])
    account.clear_connection(connected_account)
    flash_notice("#{account.name_with_asset_type} と #{connected_account.name_with_user} の取引連動設定を解除しました。")
    redirect_to(:action => 'index')
  end

end
