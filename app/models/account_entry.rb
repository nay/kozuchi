# 口座への記入データクラス
class AccountEntry < ActiveRecord::Base
  belongs_to :deal,
             :class_name => 'BaseDeal',
             :foreign_key => 'deal_id'
  belongs_to :account,
             :class_name => 'Account::Base',
             :foreign_key => 'account_id'
  belongs_to :settlement
  belongs_to :result_settlement, :class_name => 'Settlement', :foreign_key => 'result_settlement_id'

  validates_presence_of :amount, :account_id
  before_update :store_old_amount
  before_save :copy_deal_attributes
  after_save :update_balance, :request_linking

  before_destroy :assert_no_settlement
  after_destroy :update_balance, :request_unlinking

  attr_accessor :balance_estimated, :unknown_amount, :account_to_be_connected, :another_entry_account, :flow_sum
  attr_reader :new_plus_link
  attr_protected :user_id, :deal_id, :date, :daily_seq, :settlement_id, :result_settlement_id

  attr_writer :skip_unlinking

  def to_xml(options = {})
    options[:indent] ||= 4
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml_attributes = {:account => "account#{self.account_id}"}
    xml_attributes[:settlement] = "settlement#{self.settlement_id}" unless self.settlement_id.blank?
    xml_attributes[:result_settlement] = "settlement#{self.result_settlement_id}" unless self.result_settlement_id.blank?
    xml.entry(amount, xml_attributes)
  end

  def to_csv
    ["entry", self.deal_id, self.account_id, self.settlement_id, self.result_settlement_id, amount].join(',')
  end

  # 精算が紐付いているかどうかを返す。外部キーを見るだけで実際に検索は行わない。
  def settlement_attached?
    not (self.settlement_id.blank? && self.result_settlement_id.blank?)
  end

  # 相手勘定名を返す
  def mate_account_name
    raise AssociatedObjectMissingError, "no deal" unless deal
    deal.mate_account_name_for(account_id)
  end

  # リンクされたaccount_entry を返す
  # TODO: 廃止する
  def linked_account_entry
    linked_ex_entry_id ? AccountEntry.find_by_id(linked_ex_entry_id) : nil
  end

  # 所属するDealが確認済ならリンクをクリアし、未確認なら削除する
  def unlink
    raise AssociatedObjectMissingError, "my_entry.deal is not found" unless deal
    if !deal.confirmed
      # TODO: このentryについては削除したときに相手をunlink仕返さないことを指定
      # オブジェクトとしては別物なので困ってしまう
      deal.account_entries.detect{|e| e.id == self.id}.skip_unlinking = true
      deal.destroy
    else
      AccountEntry.update_all("linked_ex_entry_id = null, linked_ex_deal_id = null, linked_user_id = null", "id = #{self.id}")
      self.linked_ex_entry_id = nil
      self.linked_ex_deal_id = nil
      self.linked_user_id = nil
    end
  end

#  # 新しく連携先取引を作成する
#  # linked_account が指定されていれば、それが連携対象となっていれば登録する
#  # 指定されていなければ、連携対象が１つなら登録し、１つでなければ警告ログを吐いて登録しない
#  def create_friend_deal
#    return unless account # 他クラス依存を下げるため、accountがなければ無視する
#    return if friend_link_id # すでにある＝お手玉になる
#    partner_account = account.linked_account
#    return unless partner_account
#
#    # 相方のentry の口座が渡されていれば、その連携先が同じユーザーでこのentryの連携先以外か調べる
#    partner_other_account = connected_account_in_another_entry_other_than(partner_account)
#    # ※相方の連携先がこの口座の連携先なら、default_assetを介して２つ作るままとする。
#    # 相方 entry の連携先もこれから作る Deal となるため、相方用 deal_link を用意する。
#    # この相方用 link は、相方処理のために取り出せるよう、インスタンス変数に格納しておく
#    @new_plus_link = partner_other_account ? DealLink.create(:created_user_id => account.user_id) : nil
#
#    # 二重接続でない場合の相方口座としては、先方ユーザーにおける受け皿設定があればそれを利用する。
#    partner_other_account ||= partner_account.partner_account
#
#    # それもなければ適当な資産口座を割り当てる。
#    partner_other_account ||= partner_account.user.default_asset_other_than(partner_account)
#    return unless partner_other_account
#
#    new_minus_link = DealLink.create(:created_user_id => account.user_id)
#
#    self.friend_link_id = new_minus_link.id
#
#    friend_deal = Deal.new(
#              :minus_account_id => partner_account.id,
#              :minus_account_friend_link_id => new_minus_link.id,
#              :plus_account_id => partner_other_account.id,
#              :plus_account_friend_link_id => @new_plus_link ? @new_plus_link.id : nil,
#              :amount => self.amount,
#              :user_id => partner_account.user_id,
#              :date => self.deal.date,
#              :summary => self.deal.summary,
#              :confirmed => false
#    )
#    friend_deal.save!
#
#  end

  def after_confirmed
    update_balance
  end

  # コールバックのほか、精算提出などで単独でも呼ばれる
  def request_linking
    # すでにあるときは基本的に連動しないが、金額を更新しようとしている時はリンク解除して連携をやりなおす
    if self.linked_ex_entry_id
      if @old_amount && @old_amount.to_i != self.amount.to_i
        # TODO account_idも抱える必要がある
        request_unlinking
      else
        return
      end
    end
    return if !account || !account.linked_account || !self.deal

    # TODO: 残高は連携せず、移動だけを連携する。いずれ残高記入も連携したいがそれにはAccountEntryのクラスわけが必要か。
    self.linked_ex_entry_id, self.linked_ex_deal_id = account.linked_account.update_link_to(self.id, self.deal_id, self.user_id, self.amount, self.deal.summary, self.date)
    self.linked_user_id = account.linked_account.user_id
    self.save!
  end


  private

  def store_old_amount
    @old_amount = self.class.find(self.id).amount
  end

  def copy_deal_attributes
    return unless deal # 疎結合にするため
    self.user_id = deal.user_id
    self.date = deal.date
    self.daily_seq = deal.daily_seq
  end

  # リンクしている口座があれば、連携記入の作成/更新を相手口座に依頼する

  def request_unlinking
    return if @skip_unlinking
        # TODO: linked_account_idもほしい　関連づけかえられてたら困る
    account.linked_account.unlink_to(self.id, self.user_id) if account && account.linked_account
  end

#  def refresh_friend_link
#    if contents_updated?
#      # リンクがあれば切る
#      clear_friend_deal
#      # 作る
#      create_friend_deal
#    end
#  end

  # friend_deal とのリンクを消す。相手が未確定なら相手自身も消す。
  # 消したあとまた作られないようにstaticメソッドをつかう。
#  def clear_friend_deal
#    return unless friend_link
#    another_entry = friend_link.another(self.id)
#    friend_deal = another_entry.deal if another_entry
#
#    # リンクを消す。
#    AccountEntry.update_all("friend_link_id = null", "friend_link_id = #{self.friend_link_id}")
#    DealLink.delete(self.friend_link_id)
#
#    # このオブジェクトの状態更新
#    self.friend_link_id = nil
#    self.friend_link = nil
#
#    # 相手があり、未確定なら相手も消す。連動して配下のentryをけすため destroy
#    friend_deal.destroy if friend_deal && !friend_deal.confirmed
#  end


  def contents_updated?
    stored = AccountEntry.find(self.id)

    # 金額/残高が変更されていたら中身が変わったとみなす
    stored.amount.to_i != self.amount.to_i || stored.balance.to_i != self.balance.to_i
  end

  def assert_no_settlement
    raise "精算データに紐づいているため削除できません。さきに精算データを削除してください。" if self.settlement || self.result_settlement
  end

#  def connected_account_in_another_entry_other_than(another_account)
#    p "connected_account_in_another_entry_other_than : another_entry_account = #{self.another_entry_account}"
#    return nil unless self.another_entry_account
#    c = another_entry_account.linked_account
#    c = nil if c && (c.id == another_account.id || c.user.id != another_account.user.id)
#    p "returned #{c}"
#    return c
#  end

  # 直後の残高記入のamountを再計算する
  def update_balance
    next_balance_entry = AccountEntry.find(:first,
    :joins => "inner join deals on account_entries.deal_id = deals.id",
    :conditions => ["deals.type = 'Balance' and account_id = ? and (deals.date > ? or (deals.date = ? and deals.daily_seq > ?))", account_id, date, date, daily_seq],
    :order => "deals.date, deals.daily_seq",
    :include => :deal)
    return unless next_balance_entry
    next_balance_entry.deal.update_amount # TODO: 効率
  end

end
