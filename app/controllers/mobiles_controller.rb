class MobilesController < ApplicationController
  def create
    raise "not accessed by mobile" unless request.mobile?
    # アクセス中の端末で簡単ログイン用のハッシュをユーザーモデルに登録する
    if request.mobile.ident.blank?
      flash[:notice] = "ご利用の端末では簡単ログインを設定できません。"
    else
      current_user.update_mobile_identity(request.mobile.ident)
      flash[:notice] = "簡単ログインを設定しました。"
    end
    redirect_to home_path
  end
end
