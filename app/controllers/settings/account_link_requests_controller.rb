class Settings::AccountLinkRequestsController < ApplicationController
  before_action :find_account

  def destroy
    link_request = @account.link_requests.find(params[:id])
    # 先方のリンクを削除する。その際、こちらのrequestを削除する処理はskipする
    link_request.sender_account.clear_link(true)
    sender_account_name = link_request.sender_account.to_summary[:name_with_user]
    # こちらのrequestを削除する
    @account.link_requests.delete(link_request)
    flash[:notice] = "#{ERB::Util.h(sender_account_name)}からの連携書き込みをしないようにしました。"
    redirect_to settings_account_links_path
  end

end
