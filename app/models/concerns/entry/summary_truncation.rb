module Entry::SummaryTruncation
  extend ActiveSupport::Concern

  SUMMARY_MAX_SIZE = 64

  included do
    before_validation :truncate_summary

  end

  def summary_truncated?
    @summary_truncated
  end

  private

  def truncate_summary
    if summary && summary.length > SUMMARY_MAX_SIZE
      self.summary = summary.truncate(SUMMARY_MAX_SIZE)
      @summary_truncated = true # 登録・更新の開始時は新たにオブジェクトが作られてnilになっていることを想定している
    end
  end
end
