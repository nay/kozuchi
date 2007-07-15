# 勘定の登録・削除・変更処理の規定クラスとなるコントローラ。
class Settings::AccountsController < ApplicationController
  layout 'main'
  include TermHelper
  
  before_filter :require_post, :only => [:create, :update]
  
  protected

  # 新しい勘定を作成する。
  # params['account']['name']:: 勘定名
  # params['account']['asset_name']:: (口座の場合だけ必要)口座種類名。class.asset_name でクラスに指定された日本語の名前が入る。
  # params['account']['sort_key']:: 並び順
  def create
    account_attributes = params[:account]
    raise "no params[:account]" unless account_attributes

    account_attributes = account_attributes.clone
    asset_name = account_attributes.delete(:asset_name)
    
    account = account_class(asset_name).new(account_attributes)
    account.user_id = @user.id # params に入っていたとしても上書きするのでいいかなぁ。
    if account.save
      @user.accounts(true)
      flash[:notice]="#{account.class.type_name}「#{account.name}」を登録しました。"
    else
      flash_validation_errors(account)
    end
    redirect_to_index    
  end
  
  # 指定された勘定を削除する。
  # params[:id]:: 口座ID
  def delete
    unless params[:id]
      flash[:notice] = "#{term self.account_type}が指定されていません。"
      return redirect_to_index
    end

    begin
      target_account = @user.accounts.find(params[:id])
    rescue ActiveRecord::RecordNotFound => err
      flash[:notice]="指定された#{term self.account_type}がみつかりません。"
      return redirect_to_index
    end

    begin
      @user.accounts.delete(target_account)
      flash[:notice]="#{term self.account_type}「#{target_account.name}」を削除しました。"
    rescue Account::UsedAccountException => err
      flash[:errors]= [err.message]
    end
    
    redirect_to_index
  end

  # 複数の勘定を同時に更新する。
  # params[:account][1][name]:: id 1 の勘定名
  # params[:account][1][asset_type]:: id 1 の種別（口座の場合のみ）
  # params[:account][1][sort_key]::　id 1 の並び順
  # 好きな個数送ることができる。
  def update
    # ユーザーIDに属する以外は無視する
    # (TODO: user_id が保護されていることを確認)
    begin
      Account::Base.transaction do
        for account in @user.accounts
          break unless params[:account]
          account_attributes = params[:account][account.id.to_s]
          next unless account_attributes
          account_attributes = account_attributes.clone
          # 資産種類を変える場合はクラスを変える必要があるのでとっておく
          new_asset_name = account_attributes.delete(:asset_name)
          account.attributes = account_attributes
          account.save!
          # type の変更は object ベースではできないので sql ベースで
          Account::Base.update_all("type = '#{account_class(new_asset_name)}'", "id = #{account.id}") if new_asset_name && new_asset_name != account.asset_name
        end
      end
      flash[:notice]="すべての#{term self.account_type}を変更しました。"
#    rescue => err
#      logger.error("Exception was raised when accounts were going to be updated.")
#      logger.error(err)
#      flash[:notice]="#{term self.account_type}を変更できませんでした。"
    end
    @user.accounts(true)
    
    redirect_to_index
  end
  
  # 一覧表示する。
  def index
    @account_type = account_type # symbol
    @accounts = @user.accounts(true).select{|a|a.type_in? account_type}
    render(:template => "settings/shared/accounts")
  end
  
  private
  def redirect_to_index
    redirect_to(:action => 'index')
  end

end
