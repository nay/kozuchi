# 口座連携に関するUserモデルの処理
# 同様のI/Fを将来、UserProxyに持たせる
module User::AccountLinking


#  def clear_linked_account(account_id, skip_requester_process = false)
#    a = accounts.find(account_id)
#    a.clear_account_link(skip_requester_process) if a.link
#  end

  # 接続I/F
  # 相手システムの口座にlinkを作成する
#  def set_account_link(account_id, target_user_login, target_ex_account_name)
#    a = accounts.find(account_id)
#    a.set_account_link(target_user_login, target_ex_account_name, false, true)
#  end

#  def destroy_account_link_request(account_id, sender_id, sender_ex_account_id)
#    a = accounts.find(account_id)
#    #TODO sender_id 一意性
#    if r = a.link_requests.find_by_sender_id_and_sender_ex_account_id(sender_id, sender_ex_account_id)
#      r.skip_sender_process = true
#      r.destroy
#    end
#  end

  # このユーザー側に連携取引を作成する。すでにあれば更新する
  # proxy なら deal の中を分解して接続する
  def link_deal_for(sender_deal)
    # TODO: 抽出
    sender_entries = sender_deal.readonly_entries.find_all{|e| e.account.destination_account && e.account.destination_account.user_id == id}
    raise "sender deal #{sender_deal.id} は不正です" if sender_entries.empty?

    # すでにこの取引に紐づいたものがあるなら取得
    linked_deal = general_deals.first(:include => :readonly_entries, :conditions => "account_entries.linked_ex_deal_id = #{sender_deal.id}")
    # なければ作成
    linked_deal ||= general_deals.build(:summary => sender_deal.summary, :confirmed => false, :date => sender_deal.date)

    linked_deal.for_linking = true

    # 鏡となる entry を組上げる
    # 対応する entry をまず記入し、残りを生成する
    debtor_entries_attributes = []
    debtor_amount = 0
    creditor_entries_attributes = []
    creditor_amount = 0
    sender_entries.each do |e|
      attrs = {:account_id => e.account.destination_account.id, :amount => e.amount * -1}
      if e.amount >= 0
        creditor_entries_attributes << attrs
        creditor_amount += attrs[:amount]
      else
        debtor_entries_attributes << attrs
        debtor_amount += attrs[:amount]
      end
    end
    diff = (creditor_amount * -1) - debtor_amount
    if diff < 0
      creditor_entries_attributes << {:account_id => default_asset.id, :amount => diff}
    elsif diff > 0
      debtor_entries_attributes << {:account_id => default_asset.id, :amount => diff}
    end
    # 0 ならなにもしない
    
    linked_deal.attributes = {:debtor_entries_attributes => debtor_entries_attributes, :creditor_entries_attributes => creditor_entries_attributes}

    # 用意されたentryにリンク情報を記述する
    sender_entries.each do |e|
      account_id = e.account.destination_account.id
      amount = e.amount * -1
      prepared = if e.amount >= 0
        linked_deal.creditor_entries.detect{|le| !le.marked_for_destruction? && le.account_id == account_id && le.amount == amount}
      else
        linked_deal.debtor_entries.detect{|le| !le.marked_for_destruction? && le.account_id == account_id && le.amount == amount}
      end
      raise "could not find a prepared entry" unless prepared
      prepared.linked_ex_entry_id = e.id
      prepared.linked_ex_deal_id = sender_deal.id
      prepared.linked_user_id = sender_deal.user_id
      prepared.linked_ex_entry_confirmed = sender_deal.confirmed?
    end

    linked_deal.save! # TODO: 連携時のエラー処理の整理
    linked_entries = {}
    linked_deal.readonly_entries.find_all{|le| le.linked_user_id == sender_deal.user_id}.each do |e|
      linked_entries[e.linked_ex_entry_id] = {:entry_id => e.id, :deal_id => linked_deal.id}
    end
    linked_entries
  end

  # ここでの sender は、プロキシ経由ならシステム内のuser_idに変換されることを想定
  def unlink_deal_for(sender_id, sender_ex_deal_id)
    p "unlink_deal_for sender #{sender_id}, deal #{sender_ex_deal_id}"
    # すでにこの取引に紐づいたものがあるなら取得
    linked_deal = general_deals.first(:include => :readonly_entries, :conditions => ["account_entries.linked_user_id = ? and account_entries.linked_ex_deal_id = ?", sender_id, sender_ex_deal_id])
    p "linkd_deal = #{linked_deal.inspect}"
    return true unless linked_deal # すでになければ無視

    if linked_deal.confirmed?
      p "linked_deal.confirmed? = #{linked_deal.confirmed?}"
      linked_deal.for_linking = true
      unlinked_entry_ids = linked_deal.readonly_entries.find_all_by_linked_user_id_and_linked_ex_deal_id(sender_id, sender_ex_deal_id)
      raise "no unlinked entries" if unlinked_entry_ids.empty?
      Entry::General.update_all("linked_ex_entry_id = null, linked_ex_deal_id = null, linked_user_id = null, linked_ex_entry_confirmed = 0", ["id in (?)", unlinked_entry_ids])
    else
      p "linked_deal would be destroyed"
      linked_deal.destroy
    end
  end


  def account_with_entry_id(entry_id)
    account = entries.find_by_id(entry_id).try(:account)
    if account && block_given?
      yield account
    else
      account
    end
  end

  def find_account_id_by_name(name)
    a = accounts.find_by_name(name)
    a ? a.id : nil
  end
end
