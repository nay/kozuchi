class MobilesController < ApplicationController
  before_filter :allow_get_to_docomo

  def create_or_update
    raise "not accessed by mobile" unless request.mobile?
    # アクセス中の端末で簡単ログイン用のハッシュをユーザーモデルに登録する
    if request.mobile.ident.blank?
      flash[:notice] = "ご利用の端末では簡単ログインを設定できません。"
    else
      current_user.update_mobile_identity!(request.mobile.ident, request.user_agent)
      flash[:notice] = "簡単ログインを設定しました。"
    end
    redirect_to home_path
  end

  private
  def allow_get_to_docomo
    raise ActionController::RoutingError if request.get? && !request.mobile.docomo?
  end
end
