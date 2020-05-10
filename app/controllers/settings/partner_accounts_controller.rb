class Settings::PartnerAccountsController < ApplicationController
  menu_group "連携"
  menu "受け皿"

  before_action :find_account, :only => 'update'

  # 受け皿初期画面
  def index
    @accounts = current_user.accounts
    assets = []
    for account in @accounts
      assets << account if account.type_in? :asset
    end
    @partner_account_candidates = {}
    for account in @accounts
      # 自分が口座以外なら assets をそのまま利用
      unless account.type_in?(:asset)
        @partner_account_candidates[account] = assets
      # 自分が口座なら、自分を除くassets を作って利用
      else
        assets_without_me = assets.clone
        assets_without_me.delete(account)
        @partner_account_candidates[account] = assets_without_me
      end
    end
    
  end
  
  #更新
  def update
    @account.attributes = account_params
    @account.save!
    
    flash_notice("#{@account.name_with_asset_type}の受け皿口座を更新しました。")
    redirect_to settings_partner_accounts_path
  end

  private

  def account_params
    params.require(:account).permit(:partner_account_id)
  end

  
end
