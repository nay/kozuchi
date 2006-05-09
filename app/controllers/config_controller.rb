class ConfigController < MainController
  
  PAYMENT_TERM_MONTHS = [['当月', 0], ['翌月', 1], ['翌々月', 2]]
  
  def sub_title(action_name)
    menu_caption(action_name)
  end
  
  def initialize
    super('設定')
    add_menu('口座', {:action => 'assets'}, :action)
    add_menu('費目', {:action => 'expenses'}, :action)
    add_menu('収入内訳', {:action => 'incomes'}, :action)
    @actions = {1 => 'assets', 2 => 'expenses', 3 => 'incomes'}
    add_menu('精算ルール', {:action => 'account_rules'}, :action)
    add_menu('カスタマイズ', {:action => 'preferences'}, :action)
    add_menu('プロフィール', {:action => 'profile'}, :action)
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
    begin
      new_account.save!
      flash[:notice]="#{new_account.account_type_name} '#{new_account.name}' を登録しました。"
    rescue
      flash_validation_errors(new_account)
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
    begin
      target_account.destroy
      flash[:notice]="#{account_type_name} '#{target_account.name}' を削除しました。"
    rescue => err
      flash[:errors]= [err.message]
    end
    
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
  
  # 精算ルールのメンテナンス -----------------------------------------------------------------------
  def account_rules
    @rules = AccountRule.find_all(session[:user].id)
    @accounts_to_be_applied = Account.find_rule_free(session[:user].id)
    @accounts_to_be_associated = Account.find_all(session[:user].id, [1], [2])
    @creatable = false
    @rule = AccountRule.new
    @day_options = ConfigController.day_options
    @payment_term_months = PAYMENT_TERM_MONTHS
    if @accounts_to_be_applied.size == 0
      @explanation = "新たに精算ルールを登録できる口座（クレジットカード、債権）はありません。"
      return;
    end
    if @accounts_to_be_associated.size == 0
      @explanation = "精算ルールを登録するには、金融機関口座が必要です。"
      return;
    end
    @creatable = true
  end
  
  def self.day_options
    day_options = []
    for var in 1..28
      day_options << ["#{var}日", var]
    end
    day_options << ['末日', 0]
    day_options
  end
  
  def create_account_rule
    rule = AccountRule.new(params[:rule])
    rule.user_id = session[:user].id
    p rule.account_id
    begin
      rule.save!
      flash[:notice] = "#{rule.account.name}に精算ルールを登録しました。"
    rescue RecordInvalid => error
      flash[:notice] = "#{rule.account.name}に精算ルールを登録できませんでした。#{error}"
    end
    redirect_to(:action => 'account_rules')
  end
  
  def delete_account_rule
    target = AccountRule.get(session[:user].id, params[:id].to_i)
    if target
      target_account_name = target.account.name
      target.destroy
      flash[:notice] = "#{target_account_name}から精算ルールを削除しました。"
    else
      flash[:notice] = "精算ルールを削除できません。"
    end
    redirect_to(:action => 'account_rules')
  end
  
  def update_account_rule
    p params.to_s
    p params[:rule].to_s
    rule = AccountRule.get(user.id, params[:rule][:id].to_i)
    if rule
      rule.attributes = params[:rule]
      begin
        rule.save!
        flash[:notice] = "精算ルールを変更しました。"
      rescue
        flash_validation_errors(rule)
      end
    else
      flash_error("指定された精算ルール( #{params[:rule][:id]} )が見つかりません。 ")
    end
  
    redirect_to(:action => 'account_rules')
  end
  
  # カスタマイズ （個人的好みによる設定） ----------------------------------------------------------------
  def preferences
    @preferences = Preferences.get(user.id)
  end
  
  def update_preferences
    preferences = Preferences.get(user.id)
    preferences.attributes = params[:preferences]
    begin
      preferences.save!
      session[:user] = User.find(user.id)
      flash_notice("更新しました。")
    rescue
      flash_validation_errors(preferences)
    end
    redirect_to(:action => 'preferences')
  end
  
  # プロファイル変更（当面パスワード）
  def profile
  end
  
  def update_password
    if !params[:password] || params[:password]==""
      flash_error("パスワードを設定してください。")
    else
      if params[:password] != params[:password_confirm]
        flash_error("確認用パスワードと一致していません。もう一度入力しなおしてください。")
      else
        user.password = params[:password]
        begin
          user.save!
          flash_notice("パスワードを変更しました。")
        rescue
          flash_validation_errors(user)
        end
      end
    end
    redirect_to(:action => 'profile')
  end
end
