# -*- encoding : utf-8 -*-
# 異動明細クラス。
class Deal::General < Deal::Base

  SHOKOU = '(諸口)'

  module EntriesAssociationExtension
    def build(*args)
      record = super
      record.user_id = proxy_association.owner.user_id
      record.date = proxy_association.owner.date
      record.daily_seq = proxy_association.owner.daily_seq
      record
    end

    def not_marked
      find_all{|e| !e.marked_for_destruction?}
    end

  end

  before_destroy :cache_previous_receivers  # dependent destroy より先に

  with_options :class_name => "Entry::General", :foreign_key => 'deal_id', :extend =>  EntriesAssociationExtension do |e|
    e.has_many :debtor_entries, :conditions => "amount >= 0", :include => :account, :autosave => true
    e.has_many :creditor_entries, :conditions => "amount < 0", :include => :account, :autosave => true
    e.has_many :entries, :order => "amount", :dependent => :destroy # TODO: いずれなくして base の readonly_entries を名前変更？
  end

  accepts_nested_attributes_for :debtor_entries, :creditor_entries, :allow_destroy => true

  before_validation :set_required_data_in_entries, :set_unified_summary
  validate :validate_entries

#  before_destroy :destroy_entries
  before_update :cache_previous_receivers
  after_save :request_linkings
  after_update :respond_to_sender_when_confirmed
  after_destroy :request_unlinkings
  attr_accessor :for_linking # リンクのための save かどうかを見分ける
  attr_accessor :summary_mode # unified なら統一モードとして summary= で統一上書き。それ以外なら summary= を無視する

  [:debtor, :creditor].each do |side|
    define_method :"#{side}_entries_attributes_with_account_care=" do |attributes|
      # 金額も口座IDも入っていないentry情報は無視する
      attributes = attributes.dup
      attributes = attributes.values if attributes.kind_of?(Hash)

      # attributes が array のときは　key が相当する
      attributes.reject!{|value| value[:amount].blank? && value[:account_id].blank?}

      # 更新時は ID ではなく、内容で既存のデータと紐づける
      unless new_record?
        not_matched_old_entries = send(:"#{side}_entries", true).dup
        not_matched_new_entries = attributes

        # attirbutes の中と引き当てていく
        matched_old_entries = []
        not_matched_old_entries.each do |old|
          if matched_hash = not_matched_new_entries.detect{|new_entry_hash| new_entry_hash[:account_id].to_s == old.account_id.to_s && (Entry::Base.parse_amount(new_entry_hash[:amount]).to_s == old.amount.to_s || Entry::Base.parse_amount(new_entry_hash[:reversed_amount]).to_s == (old.amount * -1).to_s )}
            old.summary = matched_hash[:summary] # サマリーが変更されている場合に伝える
            not_matched_new_entries.delete(matched_hash)
            matched_old_entries << old
          end
        end
        not_matched_old_entries -= matched_old_entries

        # 引き当てられなかったhashからは :id をなくす
        # これにより、account_id の変更を防ぐ
        not_matched_new_entries.each do |hash|
          hash[:id] = nil # shallow copyにより attributes 内のhashが直接更新される
        end

        # 引き当てられなかったold entriesを削除予定にする
        # 現在の関連のなかの該当オブジェクトにマークする
        not_matched_old_entries.each do |old|
          e = send(:"#{side}_entries").detect{|e| e.id == old.id}
          raise "Could not find entry for 'old'" unless e
          e.mark_for_destruction
        end
      end
      send(:"#{side}_entries_attributes_without_account_care=", attributes)
    end

    alias_method_chain :"#{side}_entries_attributes=", :account_care
  end

  def summary_unified?
    (debtor_entries.map(&:summary) + creditor_entries.map(&:summary)).find_all{|s| !s.blank?}.uniq.size == 1
  end

  def summary
    @unified_summary || debtor_entries.first.summary
  end

  def reload
    @unified_summary = nil
    super
  end

  # 単一記入では creditor に金額が指定されないことへの調整。
  # 変更時のentryの同定に金額を使うため、nested_attributesによる代入前に、金額を推測して補完したい。
  # また、携帯対応のためJavaScript前提（金額補完をクライアントサーバだけで完成する）にしたくない。
  def assign_attributes(deal_attributes = {}, options = {})

    return super unless deal_attributes && deal_attributes[:debtor_entries_attributes] && deal_attributes[:creditor_entries_attributes]

    debtor_attributes = deal_attributes[:debtor_entries_attributes]
    creditor_attributes = deal_attributes[:creditor_entries_attributes]
    debtor_attributes = debtor_attributes.values if debtor_attributes.kind_of?(Hash)
    creditor_attributes = creditor_attributes.values if creditor_attributes.kind_of?(Hash)

    # 借方と借り方に有効なデータが１つだけあるとき
    if debtor_attributes.find_all{|v| v[:account_id]}.size == 1 && creditor_attributes.find_all{|v| v[:account_id]}.size == 1
      # 貸方に金額データがなければ補完する
      creditor = creditor_attributes.detect{|v| v[:account_id]}
      if !creditor[:amount] && !creditor[:reversed_amount]
        debtor = debtor_attributes.detect{|v| v[:account_id]}
        debtor_amount = debtor[:reversed_amount] ? (Entry::Base.parse_amount(debtor[:reversed_amount]).to_i * -1) : Entry::Base.parse_amount(debtor[:amount]).to_i
        creditor[:amount] = (debtor_amount * -1).to_s
        # この creditor は deal_attributes にあるものを直接書き換える
      end
    end

    super
  end

  # 内容をコピーする
  def load(from)
    self.debtor_entries_attributes = from.debtor_entries.map{|e| {:account_id => e.account_id, :amount => e.amount, :summary => e.summary}}
    self.creditor_entries_attributes = from.creditor_entries.map{|e| {:account_id => e.account_id, :amount => e.amount, :summary => e.summary}}
    self
  end


  # 貸借1つずつentry（未保存）を作成する
  def build_simple_entries
    error_if_not_empty
    debtor_entries.build
    creditor_entries.build
    self
  end

  # 複数記入用のオブジェクト（未保存）を作成する
  def build_complex_entries(size = 5)
    error_if_not_empty
    size.times do
      debtor_entries.build
      creditor_entries.build
    end
    self
  end

  # sizeに満たない場合にフィールドを補完する
  def fill_complex_entries(size = nil)
    size ||= 5
    # 大きいほうにあわせる
    size = [debtor_entries.find_all{|e| !e.marked_for_destruction?}.size, creditor_entries.find_all{|e| !e.marked_for_destruction?}.size, size].max
    while debtor_entries.find_all{|e| !e.marked_for_destruction?}.size < size
      debtor_entries.build
    end
    while creditor_entries.find_all{|e| !e.marked_for_destruction?}.size < size
      creditor_entries.build
    end
    self
  end

  def simple?
    debtor_entries.find_all{|e| !e.marked_for_destruction? }.size == 1 && creditor_entries.find_all{|e| !e.marked_for_destruction? }.size == 1
  end

  def to_s
    "Deal:#{self.id}:#{object_id}(#{user ? user.login : user.id})" + ((debtor_entries + creditor_entries).map{|e| "(#{e.account_id})#{e.amount}"}.join(','))
  end

  def to_xml(options = {})
    options[:indent] ||= 4
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.deal(:id => "deal#{self.id}", :date => self.date_as_str, :position => self.daily_seq, :confirmed => self.confirmed) do
      xml.entries do
        # include で検索している前提
        readonly_entries.each{|e| e.to_xml(:builder => xml, :skip_instruct => true)}
      end
    end
  end

  def to_csv_lines
    csv_lines = [["deal", id, date_as_str, daily_seq, confirmed].join(',')]
    readonly_entries.each{|e| csv_lines << e.to_csv}
    csv_lines
  end

  # 貸し方勘定名を返す
  def debtor_account_name
    debtor_entries # 一度全部とる
    debtor_entries.size == 1 ? debtor_entries.first.account.name : SHOKOU
  end

  def debtor_amount
    debtor_entries.inject(0){|value, entry| value += entry.amount.to_i}
  end
  # 借り方勘定名を返す
  def creditor_account_name
    creditor_entries
    creditor_entries.size == 1 ? creditor_entries.first.account.name : SHOKOU
  end

  def partner_account_name_of(e)
    raise "invalid entry" if e.deal_id != self.id
    e.amount.to_i >= 0 ? creditor_account_name : debtor_account_name
  end

  def settlement_attached?
    !readonly_entries.detect{|e| e.settlement_attached?}.nil?
  end

  # 相手勘定名を返す
  def mate_account_name_for(account_id)
    # TODO: 諸口対応、不正データ対応
    entries.detect{|e| e.account_id != account_id}.account.name
  end

  # 後の検索効率のため、idで妥協する
  scope :recent_summaries, lambda{|keyword|
    {:select => "account_entries.summary, max(deals.id) as id",
      :joins => "inner join account_entries on account_entries.deal_id = deals.id",
    :group => "account_entries.summary",
    :conditions => ["account_entries.summary like ?", "#{keyword}%"],
    :order => "deals.id desc",
    :limit => 5
    }
  }

  scope :with_account, lambda{|account_id, debtor|
   {
# account_entries との join はされている想定
     :conditions => "account_entries.account_id = #{account_id} and account_entries.amount #{debtor ? '>' : '<'} 0"
   }
  }

  # summary の前方一致で検索する
  def self.search_by_summary(user_id, summary_key, limit, account_id = nil, debtor = true)
    begin
      return [] if summary_key.empty?
      # まず summary と created_atのセットを返す
      results = if account_id
        find_by_sql("select account_entries.summary as summary, max(deals.created_at) as created_at from deals inner join account_entries on deals.id = account_entries.deal_id where account_entries.account_id = #{account_id} and account_entries.amount #{debtor ? '>' : '<'} 0 and deals.user_id = #{user_id} and deals.type='General' and account_entries.summary like '#{summary_key}%' group by account_entries.summary limit #{limit}")
      else
        find_by_sql("select account_entries.summary as summary, max(deals.created_at) as created_at from deals inner join account_entries on deals.id = account_entries.deal_id where deals.user_id = #{user_id} and deals.type='General' and account_entries.summary like '#{summary_key}%' group by account_entries.summary limit #{limit}")
      end
      return [] if results.size == 0
      conditions = ""
      for r in results
        conditions += " or " unless conditions.empty?
        conditions += "(account_entries.summary = '#{r.summary}' and deals.created_at = '#{r.created_at.to_s(:db)}')"
      end
      conditions = "deals.user_id = #{user_id} and (#{conditions})"

      options = if account_id
        conditions << " and account_entries.account_id = #{account_id} and account_entries.amount #{debtor ? '>' : '<'} 0"
        {:conditions => conditions, :joins => "inner join account_entries on deals.id = account_entries.deal_id"}
      else
        {:conditions => conditions}
      end
      options[:order] = "deals.created_at desc"
      return Deal::General.find(:all, options)
    rescue => e
      return []
    end
  end

  # 自分の取引のなかに指定された口座IDが含まれるか
  def has_account(account_id)
    for entry in entries
      return true if entry.account.id == account_id
    end
    return false
  end
  
  def entry(account_id)
    raise "no account_id in Deal::General.entry()" unless account_id
    r = entries.detect{|e| e.account_id.to_s == account_id.to_s}
    #    raise "no account_entry in deal #{self.id} with account_id #{account_id}" unless r
    r
  end

  # 指定したユーザーの指定した取引に紐づいたentryの配列を返す
  def linked_entries(remote_user_id, remote_ex_deal_id, reload = false)
    readonly_entries(reload).find_all{|e| e.linked_user_id == remote_user_id && e.linked_ex_deal_id == remote_ex_deal_id}
  end


  def unlink(sender_id, sender_ex_deal_id)
    if confirmed?
      unlink_entries(sender_id, sender_ex_deal_id)
    else
      destroy
    end
  end

  # 指定した連携を切る
  def unlink_entries(remote_user_id, remote_ex_deal_id)
    Entry::General.update_all(
      ["linked_ex_entry_id = null, linked_ex_deal_id = null, linked_user_id = null, linked_ex_entry_confirmed = ?", false],
      remote_condition(remote_user_id, remote_ex_deal_id))
  end

  def confirm_linked_entries(remote_user_id, remote_ex_deal_id)
    Entry::General.update_all(
      ["linked_ex_entry_confirmed = ?", true],
      remote_condition(remote_user_id, remote_ex_deal_id))
  end

  # 指定された他ユーザーに関係する entry を抽出してハッシュで返す
  # 口座情報は、こちらで想定している相手口座情報を入れる
  def entries_hash_for(remote_user_id)
    related_entries(remote_user_id).map do |e|
      ex_account_id = e.account.link.try(:target_ex_account_id) || e.account.link_requests.detect{|lr| lr.sender_id == remote_user_id}.sender_ex_account_id
      {:id => e.id, :ex_account_id => ex_account_id, :amount => e.amount}
    end
  end

  private

  def set_unified_summary
    if @unified_summary && @summary_mode == 'unify'
      debtor_entries.each do |e|
        e.summary = @unified_summary
      end
      creditor_entries.each do |e|
        e.summary = @unified_summary
      end
    end
  end

  def remote_condition(remote_user_id, remote_ex_deal_id)
    {:deal_id => id, :linked_user_id => remote_user_id, :linked_ex_deal_id => remote_ex_deal_id}
  end

  # 完成された entry 情報をもとに、紐づいている（と認識している）ユーザーの配列を返す
  def linked_receiver_ids(reload = false)
    receiver_ids = readonly_entries(reload).map{|e| e.linked_user_id}.compact
    receiver_ids.uniq!
    receiver_ids
  end

  # 各 entry の口座情報をもとに、こちらから連携依頼を送るべきユーザーの配列を返す
  def updated_receiver_ids(reload = false)
    receiver_ids = readonly_entries(reload).map{|e| e.account.destination_account}.compact.map(&:user_id)
    receiver_ids.uniq!
    receiver_ids
  end

  # 各 entry の口座情報をもとに、相手から連携依頼が来ると認識しているユーザーの配列を返す
  def updated_sender_ids(reload = false)
    sender_ids = readonly_entries(reload).map{|e| e.account.link_requests.map(&:sender_id)}.flatten
    sender_ids.uniq!
    sender_ids
  end

  # 変更前にこのDealから連携していたユーザーを記憶しておく
  # （変更後に連携しなくなるユーザーへ連絡するため）
  def cache_previous_receivers
    @previous_receiver_ids = linked_receiver_ids
  end

  # after_save
  # 取引連携を相手に要求
  def request_linkings
    return true if for_linking || !confirmed # 未確定のものや、連携で作られたものは連携しない
    @previous_receiver_ids ||= [] # 新規作成のときはないので用意

    updated = updated_receiver_ids(true).uniq
    deleted = (@previous_receiver_ids - updated - updated_sender_ids).uniq

    # なくなった相手に削除依頼
    deleted.each do |receiver_id|
      receiver = User.find(receiver_id)
      receiver.unlink_deal_for(user_id, id)
    end

    # 作成/更新依頼
    changed_self = false
    updated.each do |receiver_id|
      receiver = User.find(receiver_id)
      # このユーザーに関連する entry 情報（id, 口座, 金額のハッシュ）を送る
      linked_entries = receiver.link_deal_for(user_id, id, entries_hash_for(receiver_id), summary, date)
#      next unless linked_entries # false なら、こちらの変更は不要
      for entry_id, ex_info in linked_entries
        Entry::Base.update_all("linked_ex_entry_id = #{ex_info[:entry_id]}, linked_ex_deal_id = #{ex_info[:deal_id]}, linked_user_id = #{receiver.id}",  "id = #{entry_id}")
        changed_self = true
      end
    end

    if changed_self
      debtor_entries(true)
      creditor_entries(true)
      readonly_entries(true)
      entries(true)
    end
    true
  end

  def related_entries(remote_user_id)
    readonly_entries.find_all{|e| e.account.link.try(:target_user_id) == remote_user_id || e.account.link_requests.detect{|lr| lr.sender_id == remote_user_id}}
  end

  # 確認されていな状態から確認状態に変わったとき
  # destination_account に指定されている先へは request_linkings の処理で confirmed は反映されるので
  # 指定されていない先へ連絡する
  def respond_to_sender_when_confirmed
    return true unless confirmed_changed?
    sender_ids = linked_receiver_ids - updated_receiver_ids
    sender_ids.each do |sender_id|
      sender = User.find(sender_id)
      unless sender.receive_confirmation_from(user_id, id)
        # TODO: 相手がなかったときはリンクを消して終りたい
      end
    end
    true
  end


  # after destroy
  # 連携状態の削除を要求
  def request_unlinkings
    @previous_receiver_ids.each do |receiver_id|
      receiver = User.find_by_id(receiver_id)
      receiver.unlink_deal_for(user_id, id) if receiver # ユーザー削除の場合にはないケースもある
    end
  end

  def error_if_not_empty
    raise "Deal is not empty" unless creditor_entries.empty? && debtor_entries.empty?
  end

  def validate_entries
    # amount 合計が 0 でなければならない
    sum = debtor_entries.not_marked.inject(0) {|r, e| r += e.amount.to_i} + creditor_entries.not_marked.inject(0) {|r, e| r += e.amount.to_i}
    errors.add(:base, "借方、貸方が同額ではありません。") unless sum == 0

    errors.add(:base, "借方の記入が必要です。") if debtor_entries.empty?
    errors.add(:base, "貸方の記入が必要です。") if creditor_entries.empty?
  end

  def set_required_data_in_entries
    self.creditor_entries.each do |e|
      e.user_id = self.user_id
      e.date = self.date
      e.daily_seq = self.daily_seq
    end
    self.debtor_entries.each do |e|
      e.user_id = self.user_id
      e.date = self.date
      e.daily_seq = self.daily_seq
    end
  end
end
