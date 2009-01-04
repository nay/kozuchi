# 勘定にもたせる口座連携関係の機能を記述。
module Account::Linking

  def self.included(base)
    base.has_many :link_requests, :class_name => "AccountLinkRequest", :foreign_key => "account_id", :include => :sender, :dependent => :destroy
    base.has_one :link, :class_name => "AccountLink", :foreign_key => "account_id", :dependent => :destroy
  end

  # 送受信に関わらず、連携先の設定されている口座かどうかを返す
  def linked?
    self.link != nil || !self.link_requests.empty?
  end

  def linked_account
    link ? link.target_account : nil
  end

  # 送受信に関わらず、連携先の口座情報をハッシュの配列で返す。送信があるものを一番上にする。
  def linked_account_summaries(force = false)
    @linked_account_summaries = nil if force
    return @linked_account_summaries if @linked_account_summaries
    summaries = link_requests.map{|r| r.sender_account.to_summary.merge(:from => true, :request_id => r.id)}
    if link
      if interactive = summaries.detect{|s| s[:ex_id] == link.target_ex_account_id}
        interactive[:to] = true
        summaries.delete(interactive)
        summaries.insert(0, interactive)
      else
        summaries.insert(0, link.target_account.to_summary.merge(:to => true))
      end
    end
    @linked_account_summaries = summaries
  end



end
