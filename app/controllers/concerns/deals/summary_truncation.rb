module Deals::SummaryTruncation
  extend ActiveSupport::Concern

  private

  def truncation_message(deal)
    deal.summary_truncated? ? "長すぎる摘要を64文字に短縮しました。" : ""
  end
end
