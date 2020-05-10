class DealSuggestionsController < ApplicationController

  # 候補を出力する Ajax メソッド
  def index
    flash.keep

    account = if params[:account_id]
      current_user.accounts.find_by(id: params[:account_id])
    else
      nil
    end
    summary_key = params[:keyword]

    @patterns = if summary_key.blank?
      []
    else
      recent_summaries = current_user.general_entries.recent_summaries(summary_key)
      recent_summaries = recent_summaries.of(account.id) if account
      deals = Deal::General.order(id: :desc).find(recent_summaries.map(&:deal_id))

      patterns = current_user.deal_patterns.contains(summary_key).recent.limit(5)
      patterns = patterns.with_account(account.id, params[:debtor] == 'true') if account

      deals + patterns
    end
    # 臨時措置：口座別出納では複数仕訳を隠したい
    @patterns.reject!{|d| d.complex? } if account
    @patterns = @patterns.sort{|a, b| b.used_at <=> a.used_at}[0, 5]

    case params[:from]
    when 'complex_deal'
      @general_callback = 'onGeneralDealSelectedFromComplex'
    else
      @general_callback = 'onGeneralDealSelectedFromGeneral'
    end

    render partial: 'patterns'
  end

end
