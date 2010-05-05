class MobilesController < ApplicationController
  before_filter :require_mobile

  def update
    # アクセス中の端末で簡単ログイン用のハッシュをユーザーモデルに登録する
    if request.mobile.ident.blank?
      flash[:notice] = "ご利用の端末では簡単ログインを設定できません。"
    else
      current_user.update_mobile_identity!(request.mobile.ident, request.user_agent)
      flash[:notice] = "簡単ログインを設定しました。"
    end
    redirect_to home_path
  end

  def confirm_destroy
  end

  def destroy
    current_user.clear_mobile_identity!
    flash[:notice] = "設定を削除しました。"
    redirect_to home_path
  end

end
