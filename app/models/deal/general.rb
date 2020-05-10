# 異動明細クラス。
class Deal::General < Deal::Base

  before_destroy :cache_previous_receivers  # dependent destroy より先に

  with_options :class_name => "Entry::General", :foreign_key => 'deal_id', :extend =>  ::Deal::EntriesAssociationExtension do |e|
    e.has_many :debtor_entries, -> { where(creditor: false).order(:line_number).includes(:account) },
               autosave: true,
               dependent: :destroy
    e.has_many :creditor_entries, -> { where(creditor: true).order(:line_number).includes(:account) },
               autosave: true,
               dependent: :destroy
    e.has_many :entries, -> { order(:amount) },
               dependent: :destroy # TODO: いずれなくして base の readonly_entries を名前変更？
  end

  include ::Deal
  validate :validate_entries

  before_update :cache_previous_receivers
  after_save :request_linkings
  after_update :respond_to_sender_when_confirmed
  after_destroy :request_unlinkings
  attr_accessor :for_linking # リンクのための save かどうかを見分ける

  def general?
    true
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

  # サジェッション等で使う日本語部分
  def caption
    summary
  end

  # サジェッション等で使う識別子
  def css_class
    'deal'
  end

  def to_csv_lines
    csv_lines = [["deal", id, date_as_str, daily_seq, confirmed].join(',')]
    readonly_entries.each{|e| csv_lines << e.to_csv}
    csv_lines
  end

  def partner_account_name_of(e)
    raise "invalid entry" if e.deal_id != self.id
    e.amount.to_i >= 0 ? creditor_account_name : debtor_account_name
  end

  def settlement_attached?
    !readonly_entries.detect{|e| e.settlement_attached?}.nil?
  end

  # 相手勘定名を返す
  def mate_account_name_for(entry)
    if entry.creditor?
      debtor_entries.size > 1 ? '諸口' : debtor_entries.first.account.name
    else
      creditor_entries.size > 1 ? '諸口' : creditor_entries.first.account.name
    end
  end
  
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

      scope = Deal::General

      conditions = ""
      for r in results
        conditions += " or " unless conditions.empty?
        conditions += "(account_entries.summary = '#{r.summary}' and deals.created_at = '#{r.created_at.to_s(:db)}')"
      end
      conditions = "deals.user_id = #{user_id} and (#{conditions})"

      scope = scope.where(conditions).order("deals.created_at desc")

      if account_id
        scope = scope.joins("inner join account_entries on deals.id = account_entries.deal_id"
        ).where("account_entries.account_id = #{account_id} and account_entries.amount #{debtor ? '>' : '<'} 0")
      end

      return scope
    rescue => e
      return []
    end
  end

  # パターンと統一的に扱えるようにするため
  def used_at
    updated_at
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
    (reload ? readonly_entries.reload : readonly_entries).find_all{|e| e.linked_user_id == remote_user_id && e.linked_ex_deal_id == remote_ex_deal_id}
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
    Entry::General.where(remote_condition(remote_user_id, remote_ex_deal_id)).update_all(
      ["linked_ex_entry_id = null, linked_ex_deal_id = null, linked_user_id = null, linked_ex_entry_confirmed = ?", false])
  end

  def confirm_linked_entries(remote_user_id, remote_ex_deal_id)
    Entry::General.where(remote_condition(remote_user_id, remote_ex_deal_id)).update_all(
      ["linked_ex_entry_confirmed = ?", true])
  end

  # 指定された他ユーザーに関係する entry を抽出してハッシュで返す
  # 口座情報は、こちらで想定している相手口座情報を入れる
  # モードに関わらず、Entryごとのサマリーも含む
  def entries_hash_for(remote_user_id)
    related_entries(remote_user_id).map do |e|
      ex_account_id = e.account.link.try(:target_ex_account_id) || e.account.link_requests.detect{|lr| lr.sender_id == remote_user_id}.sender_ex_account_id
      {:id => e.id, :ex_account_id => ex_account_id, :amount => e.amount, :summary => e.summary}
    end
  end

  def copy_deal_info(entry)
    super
    entry.date = date
    entry.daily_seq = daily_seq
    entry.confirmed = confirmed
    entry
  end

  def modify_errors_for_simple_form
    if complex?
      modify_errors_for_complex_form # ないはずだがその場合は変える
      return
    end
    
    # 金額のエラーは借方表現だけにして、日本語は金額に (国際化まかせ)
    if errors[:"debtor_entries.amount"].present?
      errors.delete(:"creditor_entries.amount")
    elsif errors[:"creditor_entries.amount"].present?
      errors[:"debtor_entries.amount"] = errors[:"creditor_entries.amount"]
      errors.delete(:"creditor_entries.amount")
    end
  end

  private

  def remote_condition(remote_user_id, remote_ex_deal_id)
    {:deal_id => id, :linked_user_id => remote_user_id, :linked_ex_deal_id => remote_ex_deal_id}
  end

  # 完成された entry 情報をもとに、紐づいている（と認識している）ユーザーの配列を返す
  def linked_receiver_ids(reload = false)
    receiver_ids = (reload ? readonly_entries.reload : readonly_entries).map{|e| e.linked_user_id}.compact
    receiver_ids.uniq!
    receiver_ids
  end

  # 各 entry の口座情報をもとに、こちらから連携依頼を送るべきユーザーの配列を返す
  def updated_receiver_ids(reload = false)
    receiver_ids = (reload ? readonly_entries.reload : readonly_entries).map{|e| e.account.destination_account}.compact.map(&:user_id)
    receiver_ids.uniq!
    receiver_ids
  end

  # 各 entry の口座情報をもとに、相手から連携依頼が来ると認識しているユーザーの配列を返す
  def updated_sender_ids(reload = false)
    sender_ids = (reload ? readonly_entries.reload : readonly_entries).map{|e| e.account.link_requests.map(&:sender_id)}.flatten
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
      linked_entries = receiver.link_deal_for(user_id, id, entries_hash_for(receiver_id), summary_mode, summary, date)
#      next unless linked_entries # false なら、こちらの変更は不要
      for entry_id, ex_info in linked_entries
        Entry::Base.where(id: entry_id).update_all("linked_ex_entry_id = #{ex_info[:entry_id]}, linked_ex_deal_id = #{ex_info[:deal_id]}, linked_user_id = #{receiver.id}")
        changed_self = true
      end
    end

    if changed_self
      debtor_entries.reload
      creditor_entries.reload
      readonly_entries.reload
      entries.reload
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
    return true unless saved_change_to_attribute?(:confirmed)
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
      receiver = User.find_by(id: receiver_id)
      receiver.unlink_deal_for(user_id, id) if receiver # ユーザー削除の場合にはないケースもある
    end
  end

  def error_if_not_empty
    raise "Deal is not empty" unless creditor_entries.empty? && debtor_entries.empty?
  end

  def validate_entries
    # amount 合計が 0 でなければならない
    # entries 系にエラーがある場合はチェックしない
    if !debtor_entries.detect{|e| !e.valid?} && !creditor_entries.detect{|e| !e.valid?} && debtor_entries.present? && creditor_entries.present?
      sum = debtor_entries.not_marked.inject(0) {|r, e| r += e.amount.to_i} + creditor_entries.not_marked.inject(0) {|r, e| r += e.amount.to_i}
      errors.add(:base, "借方、貸方が同額ではありません。") unless sum == 0
    end

    errors.add(:base, "借方の記入が必要です。") if debtor_entries.empty?
    errors.add(:base, "貸方の記入が必要です。") if creditor_entries.empty?
  end

end
