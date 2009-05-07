class Settings::AccountLinksController < ApplicationController
  layout 'main'
  before_filter {|controller| controller.menu_group = "高度な設定"}

  before_filter :find_account, :only => [:destroy, :create_or_update]

  # 取引連動初期表示画面
  def index
    @accounts = @user.accounts(true)
    @friends = @user.friends
    @linked_accounts = @accounts.select{|a| a.linked?}
  end

  def destroy
    @account.clear_link
    flash[:notice] = "#{ERB::Util.h(@account.name_with_asset_type)}からの連携書き込みを行わないようにしました。"
    redirect_to account_links_path
  end

  def create_or_update
    if params[:linked_account_name].blank?
      flash_error("フレンドの口座名を指定してください")
      redirect_to account_links_path
      return
    end
    begin
      summary = @account.set_link(params[:linked_user_login], params[:linked_account_name], params[:require_reverse] == "1")
      flash[:notice] = "#{ERB::Util.h(summary[:name_with_user])}への連携書き込みを設定しました。"
    rescue PossibleError => e
      flash_error(ERB::Util.h(e.message))
    end
    redirect_to account_links_path
  end

  private
  def find_account
    @account = current_user.accounts.find(params[:account_id])
  end
end
