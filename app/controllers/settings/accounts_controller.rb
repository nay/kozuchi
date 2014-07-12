class Settings::AccountsController < ApplicationController
  cache_sweeper :export_sweeper
  menu_group "設定"

  before_filter :set_account_class
  before_filter :find_account, :only => [:destroy]

  # 一覧・登録フォーム
  def index
    @menu = @account_class.human_name
    @accounts = user_accounts
    @account = @account_class.new
    set_asset_kinds_option_container if @account_class.has_kind?
    render "/settings/shared/accounts/index"
  end

  # 新しい勘定を作成
  def create
    @account = user_accounts.build(account_params)
    if @account.save
      flash[:notice]="「#{ERB::Util.h @account.name}」を登録しました。"
      redirect_to action: :index
    else
      @accounts = user_accounts(true)
      set_asset_kinds_option_container if @account_class.has_kind?
      render "/settings/shared/accounts/index"
    end
  end

  def update_all
    raise InvalidParameterError unless params[:account]
    @accounts = []
    all_saved = true
    params[:account].keys.each do |id| # NOTE: Rails 4.0.2 key, value ととると value が普通のハッシュになってしまう(strong parameters が効かない)
      attributes = params[:account][id].permit(:name, :asset_kind, :sort_key)
      account = user_accounts.find(id)
      all_saved = false unless account.update_attributes(attributes)
      @accounts << account
    end
    if all_saved
      flash[:notice] = "すべての#{@account_class.human_name}を変更しました。"
      redirect_to action: :index
    else
      flash.now[:notice] = "変更できなかった#{@account_class.human_name}があります。"
      @accounts.sort!{|a, b| a.sort_key.to_i <=> b.sort_key.to_i}
      @account = @account_class.new
      set_asset_kinds_option_container if @account.has_kind?
      render :action => "index"
    end
  end

  def destroy
    begin
      @account.destroy
      flash[:notice]="「#{ERB::Util.h @account.name}」を削除しました。"
    rescue Account::Base::UsedAccountException => err
      flash[:errors]= [err.message]
    end
    redirect_to action: :index
  end

  private

  def user_accounts(*args)
    current_user.send(params[:account_type].pluralize, *args)
  end

  def set_account_class
    @account_class = Account.const_get(params[:account_type].classify)
  end

  def account_params
    params.require(:account).permit(:name, :asset_kind, :sort_key)
  end

  def find_account
    @account = user_accounts.find(params[:id])
  end

  def set_asset_kinds_option_container
    @asset_kinds_options_container = {}
    for key, attributes in current_user.available_asset_kinds
      @asset_kinds_options_container[attributes[:name]] = key.to_s
    end
  end

end
