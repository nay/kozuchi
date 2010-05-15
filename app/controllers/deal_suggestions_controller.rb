class DealSuggestionsController < ApplicationController

  # 候補を出力する Ajax メソッド
  def index
    account = if params[:account_id]
      current_user.accounts.find_by_id(params[:account_id])
    else
      nil
    end
    summary_key = params[:keyword]

    @patterns = if summary_key.blank?
      []
    else
      recent_summaries = current_user.general_deals.recent_summaries(summary_key)
      if account
        recent_summaries = recent_summaries.with_account(account.id, params[:debtor] == 'true')
      end
      Deal::General.find(recent_summaries.map(&:id), :order => "id desc")
    end

    # 臨時措置：口座別出納では複数仕訳を隠したい
    @patterns.reject!{|d| d.debtor_entries.size > 1 || d.creditor_entries.size > 1} if account

    case params[:from]
    when 'complex_deal'
      @general_callback = 'onGeneralDealSelectedFromComplex'
    else
      @general_callback = 'onGeneralDealSelectedFromGeneral'
    end

#    @patterns = summary_key.blank? ? [] : current_user.general_deals.with_summary_and_dates(
#      current_user.general_deals.recent_summaries(summary_key)).ordered_by_date
#    @patterns = Deal::General.search_by_summary(current_user.id, summary_key, 5, account.try(:id), params[:debtor] == 'true')
    render(:partial => 'patterns')
  end

end
