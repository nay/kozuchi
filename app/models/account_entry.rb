# 口座への記入データクラス
class AccountEntry < ActiveRecord::Base
  belongs_to :deal,
             :class_name => 'BaseDeal',
             :foreign_key => 'deal_id'
  belongs_to :account
  belongs_to :friend_link,
             :class_name => 'DealLink',
             :foreign_key => 'friend_link_id'
  validates_presence_of :amount
  attr_accessor :balance_estimated, :unknown_amount, :account_to_be_connected

  # ↓↓  call back methods  ↓↓

  # 新規作成時：フレンド連動があれば新しく作る
  def before_create
    create_friend_deal
  end

  # 更新時：フレンド取引があり、未確定なら更新する。確定なら関係を切って新たに登録する。
  # お手玉のケース：自分が未確定で更新されているときは確実にこの処理の相手なのではじく。確定でも friend_link がない（関係がきられた）ならはじく。
  def before_update
    p "before_update in account_entry #{self.id}:  friend_link = #{friend_link} friend_link_id = #{friend_link_id} deal.confirmed = #{deal.confirmed}"
    return unless friend_link
    return unless deal.confirmed
    another_entry = friend_link.another(self.id)
    return unless another_entry # nil when called from another_entry's before_destroy
    friend_deal = another_entry.deal
    if friend_deal.confirmed
      friend_link.destroy
 # TODO: refresh
      self.friend_link_id = nil
      self.friend_link = nil
      p "friend_link_id = #{self.friend_link_id}, friend_link = #{friend_link}"
      create_friend_deal # すでにフレンドでなければ作られない
    else
      partner_account = connected_account
      partner_other_account = Account.find_default_asset(partner_account.user_id) if partner_account
      
      if partner_account && partner_other_account
        friend_deal.attributes = {
              :user_id => partner_account.user_id,
              :minus_account_id => partner_account.id,
              :plus_account_id => partner_other_account.id,
              :amount => self.amount,
              :date => self.deal.date,
              :summary => self.deal.summary,
        }
        friend_deal.save!
      end
    end
  end
  
  def before_destroy
    p "before_destroy AccountEntry #{self.id}"
    return unless friend_link
    friend_link.destroy
  end

  # ↑↑  call back methods  ↑↑
  
  def self.balance_start(user_id, account_id, year, month)
    start_exclusive = Date.new(year, month, 1)
    return balance_at_the_start_of(user_id, account_id, start_exclusive)
  end

  def self.balance_at_the_start_of(user_id, account_id, start_exclusive)
  
    # 期限より前の最新の残高確認情報を取得する
    entry = AccountEntry.find(:first,
                      :select => "et.*",
                      :conditions => ["et.user_id = ? and et.account_id = ? and dl.date < ? and et.balance is not null", user_id, account_id, start_exclusive],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id",
                      :order => "dl.date desc, dl.daily_seq")
    # 期限より前に残高確認がない場合
    if !entry
      # 期限より後に残高確認があるか？
      entry = AccountEntry.find(:first,
                      :select => "et.*",
                      :conditions => ["et.user_id = ? and et.account_id = ? and dl.date >= ? and et.balance is not null", user_id, account_id, start_exclusive],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id",
                      :order => "dl.date, dl.daily_seq")
      # 期限より後にも残高確認がなければ、期限以前の異動合計を残高とする（初期残高０とみなす）。なければ０とする。
      if !entry
        return AccountEntry.sum("amount",
                      :conditions => ["et.user_id = ? and account_id = ? and dl.date < ? and dl.confirmed = ?", user_id, account_id, start_exclusive, true],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                      ) || 0
      # 期限より後に残高確認があれば、期首から残高確認までの異動分をその残高から引いたものを期首残高とする
      else
        return entry.balance - (AccountEntry.sum("amount",
                      :conditions => [
                        "et.user_id = ? and account_id = ? and dl.date >= ? and (dl.date < ? or (dl.date =? and dl.daily_seq < ?)) and dl.confirmed = ?",
                        user_id,
                        account_id,
                        start_exclusive,
                        entry.deal.date,
                        entry.deal.date,
                        entry.deal.daily_seq,
                        true],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                       ) || 0)
      end
      
    # 期限より前の最新残高確認があれば、それ以降の異動合計と残高を足したものとする。
    else
      return entry.balance + (AccountEntry.sum("amount",
                             :conditions => ["et.user_id = ? and account_id = ? and dl.date < ? and (dl.date > ? or (dl.date =? and dl.daily_seq > ?)) and dl.confirmed = ?",
                             user_id,
                             account_id,
                             start_exclusive,
                             entry.deal.date,
                             entry.deal.date,
                             entry.deal.daily_seq,
                             true],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                             ) || 0)
    end
  end
  
  # リンクされたaccount_entry を返す
  def linked_account_entry
    return nil unless friend_link
    return friend_link.another(self.id)
  end
  

  private
  
  def connected_account
    c = self.account_to_be_connected ? account.connected_accounts.detect{|e| e.id == connected_account.id} : nil
    if !c
      c = account.connected_accounts.size == 1 ? account.connected_accounts[0] : nil
    end
    return c
  end

  # 新しく連携先取引を作成する
  # connected_account が指定されていれば、それが連携対象となっていれば登録する
  # 指定されていなければ、連携対象が１つなら登録し、１つでなければ警告ログを吐いて登録しない
  def create_friend_deal
    p "create_friend_deal #{self.id} : friend_link_id = #{friend_link_id}"
    return unless !friend_link_id # すでにある＝お手玉になる
    p "create_friend_deal. account = #{account.id}"
    partner_account = connected_account
    p "partner_account = #{partner_account}"
    return unless partner_account
    
    partner_other_account = Account.find_default_asset(partner_account.user_id)
    p "partner_other_account = #{partner_other_account.name}"
    return unless partner_other_account
    
    new_link = DealLink.create(:created_user_id => account.user_id)
    
    self.friend_link_id = new_link.id
    
    p "going to create friend_deal."
    friend_deal = Deal.new(
              :minus_account_id => partner_account.id,
              :minus_account_friend_link_id => new_link.id,
              :plus_account_id => partner_other_account.id,
              :amount => self.amount,
              :user_id => partner_account.user_id,
              :date => self.deal.date,
              :summary => self.deal.summary,
              :confirmed => false
    )
    friend_deal.save!
    p "saved friend_deal #{friend_deal.id}"
    
  end

end
