# 口座連携に関するUserモデルの処理
# 同様のI/Fを将来、UserProxyに持たせる
module User::AccountLinking

  class AccountHasDifferentLinkError < PossibleError
  end

  # 依頼を受けて、target_account から client_account への連携を作成する
  # すでに client_account 以外へリンクしている場合は何もせず、falseを返す
  # Accountに実装してもいいが、相手システム側のコードをUserに寄せたほうがわかりやすいのでこちらに
  def link_account(target_account_id, client_id, client_account_id)
    target_account = accounts.find(target_account_id)
    client = User.find(client_id)
    client_account = client.accounts.find(client_account_id)
    # ここまでで不一致があれば例外が発生

    # すでに別の口座にリンクしているため、依頼では勝手に書き換えられない
    raise AccountHasDifferentLinkError, "already linked to #{target_account.link.try(:account).try(:name)} in user #{login}, though the client account is #{client_account.name}" if target_account.link && target_account.link.target_ex_account_id != client_account.id

    # TODO: accountにはexつけないのがただしそう
    target_account.link = AccountLink.new(:target_user_id => client_id, :target_ex_account_id => client_account_id)
    raise "the link could not be saved. #{target_account.link.errors.full_messages.join(' ')}" if target_account.link.new_record?
    true
  end

  # 依頼を受けて、特定勘定から連携されているという受け取り側の状態を作成する
  def create_link_request(target_account_id, sender_id, sender_ex_account_id)
    target_account = accounts.find(target_account_id)
    link_request = target_account.link_requests.find_or_create_by(account_id: target_account_id, sender_id: sender_id, sender_ex_account_id: sender_ex_account_id)
    raise "could not save link_request. #{link_request.errors.full_messages.join(' ')}" if link_request.new_record?
    true
  end

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
  def link_deal_for(sender_id, sender_ex_deal_id, ex_entries_hash, summary_mode, summary, date)

    # 連携側でないほうのサマリーを準備する
    partner_entry_summary = ex_entries_hash.first[:summary] # 連携entryが1つまたはunifyのとき
    if summary_mode == 'split' && ex_entries_hash.size > 1 && partner_entry_summary.present?
      partner_entry_summary = "#{partner_entry_summary.truncate(Entry::Base::SUMMARY_MAX_SIZE - 2)}、他"
    end

    # すでにこの取引に紐づいたものがあるなら取得
    linked_deal = linked_deal_for(sender_id, sender_ex_deal_id)
    if linked_deal
      # 対応する entry を取り出す
      linked_entries = linked_deal.linked_entries(sender_id, sender_ex_deal_id).sort{|a, b| a[:id] <=> b[:id] }
      # 金額や口座構成の変更があったかを検出する。
      ex_entries_hash_without_summary = ex_entries_hash.map{|h| h.except(:summary)}
      supposed_hash = linked_entries.map{|e| {:id => e.linked_ex_entry_id, :ex_account_id => e.account_id, :amount => e.amount * -1 }}.sort{|a, b| a[:id] <=> b[:id] }
      if supposed_hash == ex_entries_hash_without_summary
        # 変更がなければ相手方を確定する
        linked_deal.confirm_linked_entries(sender_id, sender_ex_deal_id)
        # 未確認の場合、summary, date を更新する
        unless linked_deal.confirmed?
          linked_deal.date = date
          Deal::General.where(id: linked_deal.id).update_all(["date = ?", date])
          linked_deal.summary_mode = summary_mode
          if summary_mode == 'unify'
            linked_deal.summary = summary # 使わないが念のためあわせておく
            Entry::General.where(deal_id: linked_deal.id).update_all(["summary = ?", summary])
          else
            linked_entries_side = nil
            linked_entries.each do |e|
              ex_e = ex_entries_hash.detect{|h| h[:id] == e.linked_ex_entry_id }
              e.summary = ex_e[:summary]
              Entry::General.where(id: e.id).update_all(["summary = ?", ex_e[:summary]])
              linked_entries_side ||= e.creditor ? :creditor : :debtor
            end
            # 未確認なら相手entryは1つである想定だけど全部としておく
            # ここでsaveしたくないみたいだけどはじめての連携時はsaveしちゃってるし、いったん相手のほうはサマリー変更を終わらせる
            (linked_entries_side == :creditor? ? linked_deal.debtor_entries : linked_deal.creditor_entries).each{|e| e.update_columns(summary: partner_entry_summary)}
          end
        end

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
    linked_deal ||= general_deals.build(:summary => summary_mode == 'unify' ? summary : nil, :summary_mode => summary_mode, :confirmed => false, :date => date)

    linked_deal.for_linking = true

    # 鏡となる entry を組上げる
    # 対応する entry をまず記入し、残りを生成する
    debtor_entries_attributes = []
    debtor_amount = 0
    debtor_line_number = -1
    creditor_entries_attributes = []
    creditor_amount = 0
    creditor_line_number = -1
    used_accounts = []
    ex_entries_hash.each do |e|
      account = accounts.find(e[:ex_account_id])
      used_accounts << account
      amount = e[:amount] * -1
      attrs = {:account_id => account.id, :amount => amount, :summary => summary_mode == 'unify' ? nil : e[:summary], :linked_ex_entry_id => e[:id], :linked_ex_deal_id => sender_ex_deal_id, :linked_user_id => sender_id, :linked_ex_entry_confirmed => true}
      if amount < 0
        creditor_entries_attributes << attrs.merge(:line_number => creditor_line_number += 1)
        creditor_amount += amount
      else
        debtor_entries_attributes << attrs.merge(:line_number => debtor_line_number += 1)
        debtor_amount += amount
      end
    end
    diff = (creditor_amount * -1) - debtor_amount
    partner_account = default_asset_other_than(*used_accounts)
    raise "could not find safe partner account. " unless partner_account

    if diff < 0
      creditor_entries_attributes << {:account_id => partner_account.id, :amount => diff, :line_number => creditor_line_number += 1, summary: partner_entry_summary}
    elsif diff > 0
      debtor_entries_attributes << {:account_id => partner_account.id, :amount => diff, :line_number => debtor_line_number += 1, summary: partner_entry_summary}
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
    general_deals.includes(:readonly_entries).references(:readonly_entries).
        where("account_entries.linked_user_id = ? and account_entries.linked_ex_deal_id = ?", remote_user_id, remote_ex_deal_id).first
  end

  # こちらから一方的に連携している相手からの確認を受け取る
  def receive_confirmation_from(remote_user_id, remote_ex_deal_id)
    linked_deal = linked_deal_for(remote_user_id, remote_ex_deal_id)
    return false unless linked_deal
    linked_deal.confirm_linked_entries(remote_user_id, remote_ex_deal_id)
    true
  end


  def account_with_entry_id(entry_id)
    account = entries.find_by(id: entry_id).try(:account)
    if account && block_given?
      yield account
    else
      account
    end
  end

  def find_account_id_by_name(name)
    a = accounts.find_by(name: name)
    a ? a.id : nil
  end
end
