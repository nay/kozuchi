class DealSuggestionsController < ApplicationController

  # 候補を出力する Ajax メソッド
  def index
    account = if params[:account_id]
      current_user.accounts.find_by_id(params[:account_id])
    else
      nil
    end
    summary_key = params[:keyword]
    @patterns = Deal::General.search_by_summary(current_user.id, summary_key, 5, account.try(:id), params[:debtor] == 'true')
    render(:partial => 'patterns')
  end

end
