# -*- encoding : utf-8 -*-
class DealPatternsController < ApplicationController

  # 仕訳帳・口座別出納などの記入フォームからの、Ajax による簡易なパターン登録
  # 最近のパターン10件エリアの表示内容を返す
  def create
    deal_pattern = Pattern::Deal.new(params[:deal])
    deal_pattern.user_id = current_user.id
    deal_pattern.save!

    @deal_patterns = Pattern::Deal.order('updated_at desc').limit(10)

    render :partial => 'new_arrivals'
  end

end
