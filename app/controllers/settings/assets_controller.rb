class Settings::AssetsController < ApplicationController
  layout 'main'
  cache_sweeper :export_sweeper
  menu_group "設定"
  menu "口座"

  before_filter :find_account, :only => [:destroy]

  # 一覧表示する。
  def index
    @account_type = account_type # symbol # TODO
    @accounts = current_user.assets
    @account = Account::Asset.new
    set_asset_kinds_option_container
  end

  # 新しい勘定を作成する。
  def create
    @account = current_user.assets.build(params[:account])
    if @account.save
      flash[:notice]="「#{ERB::Util.h @account.name}」を登録しました。"
      redirect_to settings_assets_path
    else
      @accounts = current_user.assets(true)
      set_asset_kinds_option_container
      render :action => "index"
    end
  end

  def update_all
    raise InvalidParameterError unless params[:account]
    @accounts = []
    all_saved = true
    for id, attributes in params[:account] do
      account = current_user.assets.find(id)
      all_saved = false unless account.update_attributes(attributes)
      @accounts << account
    end
    if all_saved
      flash[:notice] = "すべての#{Account::Asset.human_name}を変更しました。"
      redirect_to settings_assets_path
    else
      flash.now[:notice] = "変更できなかった#{Account::Asset.human_name}があります。"
      @accounts.sort!{|a, b| a.sort_key.to_i <=> b.sort_key.to_i}
      @account = Account::Asset.new
      set_asset_kinds_option_container
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
    redirect_to settings_assets_path
  end

  
  protected
  def account_type
    :asset
  end
  
  private
  def find_account
    @account = current_user.assets.find(params[:id])
  end

  def set_asset_kinds_option_container
    @asset_kinds_options_container = {}
    for key, attributes in current_user.available_asset_kinds
      @asset_kinds_options_container[attributes[:name]] = key.to_s
    end
  end

end
