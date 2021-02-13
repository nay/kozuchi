class DealPatternsController < ApplicationController

  # 仕訳帳・口座別出納などの記入フォームからの、Ajax による簡易なパターン登録
  # 最近のパターン10件エリアの表示内容を返す
  def create
    current_user.deal_patterns.create!(deal_params)
    # TODO: 通常利用ではあまり発生しないはずだが、エラー時の処理

    render :partial => '/shared/deal_patterns/recent'
  end

  def recent
    render :partial => '/shared/deal_patterns/recent'
  end

end
