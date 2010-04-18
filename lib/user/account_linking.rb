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
