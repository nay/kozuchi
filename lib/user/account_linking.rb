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
  def link_deal_for(sender_id, sender_ex_deal_id, ex_entries_hash, summary, date)
    # すでにこの取引に紐づいたものがあるなら取得
    linked_deal = linked_deal_for(sender_id, sender_ex_deal_id)
    if linked_deal
      # 対応する entry を取り出す
      linked_entries = linked_deal.linked_entries(sender_id, sender_ex_deal_id)
      # 金額や口座構成の変更があったかを検出する。
      supposed_hash = linked_entries.map{|e| {:id => e.linked_ex_entry_id, :ex_account_id => e.account_id, :amount => e.amount * -1 }}
      if supposed_hash == ex_entries_hash
        # 変更がなければ確定だけしておわる
        linked_deal.confirm_linked_entries(sender_id, sender_ex_deal_id)

        linked_entries = {}
        linked_deal.readonly_entries.find_all{|le| le.linked_user_id == sender_id}.each do |e|
          linked_entries[e.linked_ex_entry_id] = {:entry_id => e.id, :deal_id => linked_deal.id}
        end
        return linked_entries  # データ不正で呼び出し側にないときがあるので同じように返す
      else
        # 変更があったら、連携を切って（未確認なら削除して）新しく作る
        linked_deal.unlink(sender_id, sender_ex_deal_id)
        linked_deal = nil
      end
    end
    # なければ作成
    linked_deal ||= general_deals.build(:summary => summary, :confirmed => false, :date => date)

    linked_deal.for_linking = true

    # 鏡となる entry を組上げる
    # 対応する entry をまず記入し、残りを生成する
    debtor_entries_attributes = []
    debtor_amount = 0
    creditor_entries_attributes = []
    creditor_amount = 0
    used_accounts = []
    ex_entries_hash.each do |e|
      account = accounts.find(e[:ex_account_id])
      used_accounts << account
      amount = e[:amount] * -1
      attrs = {:account_id => account.id, :amount => amount, :linked_ex_entry_id => e[:id], :linked_ex_deal_id => sender_ex_deal_id, :linked_user_id => sender_id, :linked_ex_entry_confirmed => true}
      if amount < 0
        creditor_entries_attributes << attrs
        creditor_amount += amount
      else
        debtor_entries_attributes << attrs
        debtor_amount += amount
      end
    end
    diff = (creditor_amount * -1) - debtor_amount
    partner_account = default_asset_other_than(*used_accounts)
    raise "could not find safe partner account. " unless partner_account

    if diff < 0
      creditor_entries_attributes << {:account_id => partner_account.id, :amount => diff}
    elsif diff > 0
      debtor_entries_attributes << {:account_id => partner_account.id, :amount => diff}
    end
    # 0 ならなにもしない
    
    linked_deal.attributes = {:debtor_entries_attributes => debtor_entries_attributes, :creditor_entries_attributes => creditor_entries_attributes}

    linked_deal.save! # TODO: 連携時のエラー処理の整理

    linked_entries = {}
    linked_deal.readonly_entries.find_all{|le| le.linked_user_id == sender_id}.each do |e|
      linked_entries[e.linked_ex_entry_id] = {:entry_id => e.id, :deal_id => linked_deal.id}
    end
    linked_entries
  end

  # 連携削除依頼を受ける
  # ここでの sender は、プロキシ経由ならシステム内のuser_idに変換されることを想定
  def unlink_deal_for(sender_id, sender_ex_deal_id)
    # すでにこの取引に紐づいたものがあるなら取得
    linked_deal = linked_deal_for(sender_id, sender_ex_deal_id)
    return unless linked_deal # すでになければ無視

    linked_deal.unlink(sender_id, sender_ex_deal_id)
  end

  def linked_deal_for(remote_user_id, remote_ex_deal_id)
    general_deals.first(:include => :readonly_entries, :conditions => ["account_entries.linked_user_id = ? and account_entries.linked_ex_deal_id = ?", remote_user_id, remote_ex_deal_id])
  end

  # こちらから一方的に連携している相手からの確認を受け取る
  def receive_confirmation_from(remote_user_id, remote_ex_deal_id)
    linked_deal = linked_deal_for(remote_user_id, remote_ex_deal_id)
    return false unless linked_deal
    linked_deal.confirm_linked_entries(remote_user_id, remote_ex_deal_id)
    true
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
