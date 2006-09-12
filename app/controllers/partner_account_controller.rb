class PartnerAccountController < ApplicationController
  include ExpertConfigMenues
  layout 'main'

  # 受け皿初期画面
  def index
    @accounts = Account.find_all(user.id, [Account::ACCOUNT_ASSET, Account::ACCOUNT_EXPENSE, Account::ACCOUNT_INCOME])
    assets = []
    for account in @accounts
      assets << account if account.account_type == Account::ACCOUNT_ASSET
    end
    @partner_account_candidates = {}
    for account in @accounts
      # 自分が口座以外なら assets をそのまま利用
      if account.account_type != Account::ACCOUNT_ASSET
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
    account_id = params[:account][:id]
    account = Account.get(user.id, account_id.to_i)
    partner_account_id = params[:account][:partner_account_id]
    raise "error" if partner_account_id == nil
    p "partner_account_id = #{partner_account_id}"
    if partner_account_id && partner_account_id.empty?
      account.partner_account_id = nil
    else
      account.partner_account_id = partner_account_id.to_i
    end
    account.save!
    
    flash_notice("#{account.name_with_asset_type}の受け皿口座を更新しました。")
    redirect_to(:action => 'index')
  end
  
end
