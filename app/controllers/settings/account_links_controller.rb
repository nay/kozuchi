class Settings::AccountLinksController < ApplicationController
  menu_group "連携"
  menu "連携"

  before_action :find_account, :only => [:destroy, :create]

  # 取引連動初期表示画面
  def index
    @accounts = current_user.accounts
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
    begin
      target_user = User.find_by(login: params[:linked_user_login])
      raise PossibleError, "フレンドの口座名を指定してください" if params[:linked_account_name].blank?
      target_account = target_user ? target_user.accounts.find_by(name: params[:linked_account_name]) : nil
      # とれてなければset_link内でエラーとなる
      @account.set_link(target_user, target_account, params[:require_reverse] == "1")
      flash[:notice] = "#{ERB::Util.h(target_account.name_with_user)}への連携書き込みを設定しました。"
    rescue User::AccountLinking::AccountHasDifferentLinkError => e
      flash[:notice] = "#{ERB::Util.h(target_account.name_with_user)}への連携書き込みを設定しましたが、相手の口座にはすでに別の連携先があるため、双方向の連携を設定できませんでした。"
    rescue PossibleError => e
      flash[:form] = params.slice(:account_id, :linked_account_name, :linked_user_login, :linked_account_name, :require_reverse)
      flash_error(ERB::Util.h(e.message))
    end
    redirect_to settings_account_links_path
  end

end
