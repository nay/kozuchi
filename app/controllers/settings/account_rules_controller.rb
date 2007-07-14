class Settings::AccountRulesController < ApplicationController
  layout 'main'
  
  PAYMENT_TERM_MONTHS = [['当月', 0], ['翌月', 1], ['翌々月', 2]]  
  
  # 精算ルールのメンテナンス -----------------------------------------------------------------------
  def index
    @rules = AccountRule.find_all(@user.id)
    @accounts_to_be_applied = Account::Asset.find_rule_free(@user.id)
    @accounts_to_be_associated = @user.accounts.types_in(:banking_facility)
    @creatable = false
    @rule = AccountRule.new
    @day_options = self.class.day_options
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
    rule.user_id = @user.id
    p rule.account_id
    begin
      rule.save!
      flash[:notice] = "#{rule.account.name}に精算ルールを登録しました。"
    rescue ActiveRecord::RecordInvalid => error
      flash[:notice] = "#{rule.account.name}に精算ルールを登録できませんでした。#{error}"
    end
    redirect_to(:action => 'index')
  end
  
  def delete_account_rule
    target = AccountRule.get(@user.id, params[:id].to_i)
    if target
      target_account_name = target.account.name
      target.destroy
      flash[:notice] = "#{target_account_name}から精算ルールを削除しました。"
    else
      flash[:notice] = "精算ルールを削除できません。"
    end
    redirect_to(:action => 'index')
  end
  
  def update_account_rule
    p params.to_s
    p params[:rule].to_s
    rule = AccountRule.get(@user.id, params[:rule][:id].to_i)
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
  
    redirect_to(:action => 'index')
  end
  
end
