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

  # この口座のあるシステムの指定されたEntryと紐づくEntryおよびDealを作成/更新する
  def update_link_to(linked_ex_entry_id, linked_ex_deal_id, linked_user_id, linked_entry_amount, linked_entry_summary, linked_entry_date)
    # すでに紐づいたAccountEntryが存在する場合
    my_entry = account_entries.find_by_linked_ex_entry_id_and_linked_user_id(linked_ex_entry_id, linked_user_id)
    # 存在し、金額が同じ（正負逆の同額）なら変更不要
    if my_entry
      return if my_entry.amount == linked_entry_amount * -1
      # 金額が変わっていた場合は、未確認なら取引を削除、確認済ならリンクを削除する
      raise AssociatedObjectMissingError, "my_entry.deal is not found" unless my_entry.deal
      if my_entry.deal.confirmed
        my_entry.deal.destroy
      else
        my_entry.linked_ex_entry_id = nil
        my_enrty.linked_user_id = nil
        my_entry.save!(false)
      end
    elsif mate_entry = account_entries.find_by_linked_ex_deal_id(linked_ex_deal_id)
      # まだlinked_ex_entry_idが入っていなくても、今回リクエストのあった相手側のDealとすでに紐付いているAccountEntryがあれば、それの相手が求める勘定となる
      # entry数が2でないものはデータ不正
      raise "entry size should be 2" unless mate_entry.deal.account_entries.size == 2
      my_entry = mate_entry.deal.account_enrtries.detect{|e| e.id != mate_entry.id}
      my_entry.linked_ex_entry_id = linked_ex_entry_id
      my_entry.linked_ex_deal_id = linked_ex_deal_id
      my_entry.linked_user_id = linked_user_id
      my_entry.save!(false)
    else
      # 新しく作成する
      mate_account = self.partner_account || user.default_asset_other_than(self)

      deal = user.deals.build(
        :summary => linked_entry_summary,
        :date => linked_entry_date,
        :confirmed => false)
      my_entry = deal.account_entries.build(
        :account_id => self.id,
        :amount => linked_entry_amount * -1)
      my_entry.linked_ex_entry_id = linked_ex_entry_id
      my_entry.linked_ex_deal_id = linked_ex_deal_id
      my_entry.linked_user_id = linked_user_id
      deal.account_entries.build(
        :account_id => mate_account.id,
        :amount => linked_entry_amount)
      deal.save!
    end
  end

end
