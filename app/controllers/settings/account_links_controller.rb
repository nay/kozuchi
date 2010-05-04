class Settings::AccountLinksController < ApplicationController
  layout 'main'
  menu_group "連携"
  menu "取引連動"

  before_filter :find_account, :only => [:destroy, :create]

  # 取引連動初期表示画面
  def index
    @accounts = current_user.accounts(true)
    @friends = current_user.friends
    @linked_accounts = @accounts.select{|a| a.linked?}
  end

  def destroy
    @account.clear_link
    flash[:notice] = "#{ERB::Util.h(@account.name_with_asset_type)}からの連携書き込みを行わないようにしました。"
    redirect_to settings_account_links_path
  end

  # すでにある場合は更新する
  def create
    if params[:linked_account_name].blank?
      flash_error("フレンドの口座名を指定してください")
      redirect_to settings_account_links_path
      return
    end
    begin
      summary = @account.set_link(params[:linked_user_login], params[:linked_account_name], params[:require_reverse] == "1")
      flash[:notice] = "#{ERB::Util.h(summary[:name_with_user])}への連携書き込みを設定しました。"
    rescue PossibleError => e
      flash_error(ERB::Util.h(e.message))
    end
    redirect_to settings_account_links_path
  end

end
