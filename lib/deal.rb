module Deal

  module AccountCareExtension
    [:debtor, :creditor].each do |side|
      define_method :"#{side}_entries_attributes=" do |attributes|
        # 金額も口座IDも摘要も入っていないentry情報は無視する
        attributes = attributes.values if attributes.kind_of?(Hash)
        attributes.reject!{|value| value[:amount].blank? && value[:reversed_amount].blank? && value[:account_id].blank? && value[:summary].blank?}

        # 更新時は必ずしも ID ではなく、内容で既存のデータと紐づける
        unless new_record?
          old_entries = Array.new(send("#{side}_entries").reload)

          # attirbutes の中と引き当てていく
          matched_old_entries = []
          matched_new_entries = []
          not_matched_new_entries = attributes.dup
          old_entries.each do |old|
            if matched_hash = not_matched_new_entries.detect{|new_entry_hash| old.matched_with_attributes?(new_entry_hash) }
              not_matched_new_entries.delete_if{|entry_hash| entry_hash.equal?(matched_hash)}
              matched_hash[:id] = old.id.to_s # IDを付け替える
              matched_old_entries << old
              matched_new_entries << matched_hash
            end
          end
          not_matched_old_entries = old_entries - matched_old_entries

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

        # もとの（空は削除された）attributesを渡す。更新時は中のハッシュのidが加工された状態。
        super attributes
      end
    end

  end


  SHOKOU = '(諸口)'

  module EntriesAssociationExtension
    def build(*args)
      record = super
      proxy_association.owner.copy_deal_info(record)
    end

    def not_marked
      find_all{|e| !e.marked_for_destruction?}
    end

  end

  attr_accessor :summary_mode # unified なら統一モードとして summary= で統一上書き。それ以外なら summary= を無視する

  def self.included(base)
    base.accepts_nested_attributes_for :debtor_entries, :creditor_entries, :allow_destroy => true
    base.before_validation :copy_deal_info_to_entries, :set_creditor_to_entries, :set_unified_summary
    base.after_validation :get_summary_truncated # 後の工程でentryオブジェクトが入れ替わってしまい状態が失われるので取得しておく
    base.before_save :adjust_entry_line_numbers
    base.before_update :destroy_marked_entries
    base.after_save :clear_unified_summary # entry側でtruncateされて変化したときにそれをsummaryとして扱えるようにする

    base.class_eval do
      # 単一記入では creditor に金額が指定されないことへの調整。
      # 変更時のentryの同定に金額を使うため、nested_attributesによる代入前に、金額を推測して補完したい。
      # また、携帯対応のためJavaScript前提（金額補完をクライアントサーバだけで完成する）にしたくない。
      def assign_attributes(deal_attributes = {})
        return super unless deal_attributes && deal_attributes[:debtor_entries_attributes] && deal_attributes[:creditor_entries_attributes]

        debtor_attributes = deal_attributes[:debtor_entries_attributes]
        creditor_attributes = deal_attributes[:creditor_entries_attributes]
        debtor_attributes = debtor_attributes.values unless debtor_attributes.kind_of?(Array)
        creditor_attributes = creditor_attributes.values unless creditor_attributes.kind_of?(Array)

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
      alias_method :attributes=, :assign_attributes # NOTE: Rails 4.0.2 これをやらないとattributes=が古いままとなる

      prepend AccountCareExtension
    end

  end

  def complex?
    debtor_entries.not_marked.size > 1 || creditor_entries.not_marked.size > 1
  end

  def simple?
    !complex?
  end

  def debtor_amount
    nil if debtor_entries.detect{|e| e.amount.nil? }
    debtor_entries.inject(0){|value, entry| value += entry.amount.to_i}
  end

  # TODO: 関連を消したら名前変更
  # readonly_entries から計算で求める
  def readonly_creditor_entries
    readonly_entries.find_all{|e| e.creditor? }.sort_by(&:line_number)
  end
  def readonly_debtor_entries
    readonly_entries.find_all{|e| !e.creditor? }.sort_by(&:line_number)
  end

  # 借り方勘定名を返す
  def creditor_account_name
    readonly_creditor_entries.size == 1 ? readonly_creditor_entries.first.account.try(:name) : SHOKOU
  end

  # 貸し方勘定名を返す
  def debtor_account_name
    readonly_debtor_entries.size == 1 ? readonly_debtor_entries.first.account.try(:name) : SHOKOU
  end

  def load(from)
    self.debtor_entries_attributes = from.debtor_entries.map(&:copyable_attributes) #{|e| {:account_id => e.account_id, :amount => e.amount, :summary => e.summary}}
    debtor_entries.build if debtor_entries.empty?
    self.creditor_entries_attributes = from.creditor_entries.map(&:copyable_attributes) #{|e| {:account_id => e.account_id, :amount => e.amount, :summary => e.summary}}
    creditor_entries.build if creditor_entries.empty?
    self
  end

  def copy_deal_info(entry)
    entry.user_id = user_id
    entry
  end

  def summary_unified?
    summary_mode != 'split' && active_entries.map(&:summary).find_all{|s| !s.blank?}.uniq.size == 1
  end

  def summary=(s)
    @unified_summary = s
  end

  def summary
    @unified_summary || active_entries.detect{|e| e.summary.present?}.try(:summary) || ''
  end

  def active_entries
    (debtor_entries.loaded? || creditor_entries.loaded?) ? (debtor_entries.find_all{|e| !e.marked_for_destruction? } + creditor_entries.find_all{|e| !e.marked_for_destruction? }) : readonly_entries
  end

  def reload
    clear_unified_summary
    super
  end

  # sizeに満たない場合にフィールドを補完する
  # line_numberが飛び石になっている場合に間に空フィールドを挟む処理も行う
  # 未保存オブジェクトをリストの間に挿入するAPIがhas_many関連にないので、関連proxyからtargetを直接使う
  # 削除マークありのオブジェクトがない前提
  def fill_complex_entries(size = nil)
    size ||= 5
    # 大きいほうにあわせる
    # lastが最大であるはずだが、更新直後などはソートできてないかもしれないので全部で比較
    # 5行用意するということは最後の行は4
    max_line_number = (debtor_entries.map(&:line_number) + creditor_entries.map(&:line_number) + [size-1]).max

    for line_number in 0..max_line_number
      unless debtor_entries.detect{|e| e.line_number.to_i == line_number}
        # この行があればそのまま
        # なければ、追加してソートする
        debtor_entries.build(:line_number => line_number)
        association(:debtor_entries).target.sort!{|a, b| a.line_number.to_i <=> b.line_number.to_i}
      end

      unless creditor_entries.detect{|e| e.line_number.to_i == line_number}
        # この行があればそのまま
        # なければ、追加してソートする
        creditor_entries.build(:line_number => line_number)
        association(:creditor_entries).target.sort!{|a, b| a.line_number.to_i <=> b.line_number.to_i}
      end
    end

    self
  end

  # どのようにエラーを補正すればいいかはどのI/Fから使うかによるため明示的に呼ぶ仕様とする
  def modify_errors_for_complex_form
    debtor_entries.each_with_index do |e, i|
      e.errors.each do |attr, message|
        errors.add(:base, "借方(#{i+1})：" + e.errors.full_message(attr, message))
        errors.delete(:"debtor_entries.#{attr}")
      end
    end
    creditor_entries.each_with_index do |e, i|
      e.errors.each do |attr, message|
        errors.add(:base, "貸方(#{i+1})：" + e.errors.full_message(attr, message))
        errors.delete(:"creditor_entries.#{attr}")
      end
    end
  end

  def summary_truncated?
    @summary_truncated
  end

  private

  def get_summary_truncated
    @summary_truncated = active_entries.any?(&:summary_truncated?)
  end

  def clear_unified_summary
    @unified_summary = nil
  end

  # Rails を 3.2.6 から 3.2.11 にあげたら、
  # nested attributes の autosave で削除よりさきにentry登録がはしって
  # index重複エラーになったので、
  # その回避として明示的に先に削除する
  def destroy_marked_entries
    while e = debtor_entries.detect{|e| e.marked_for_destruction?} do
      debtor_entries.delete(e)
    end
    while e = creditor_entries.detect{|e| e.marked_for_destruction?} do
      creditor_entries.delete(e)
    end
  end

  # Entryのline_numberを調整する
  def adjust_entry_line_numbers
    if debtor_entries.size == 1 && creditor_entries.size == 1
      # 1:1 の場合は強制で双方0にする
      debtor_entries.first.line_number = creditor_entries.first.line_number = 0
    else
      # 複数仕訳の場合、途中にある完全空白行は詰める
      line_number = 0

      # 引き当てなどをした結果、順序が逆になっている場合がある
      debtors = debtor_entries.not_marked.sort{|a, b| a.line_number <=> b.line_number}
      creditors = creditor_entries.not_marked.sort{|a, b| a.line_number <=> b.line_number}

      # line_number に重複がある（代入漏れなどで）場合はループ前提が崩れるため先にエラーにする
      raise "Duplicated line number in debtor entries. #{debtors.inspect}" if debtors.map(&:line_number).uniq.size != debtors.size
      raise "Duplicated line number in creditor entries. #{creditors.inspect}" if creditors.map(&:line_number).uniq.size != creditors.size

      while((!debtors.empty? || !creditors.empty?) && line_number <= Entry::Base::MAX_LINE_NUMBER)
        exists = false
        # どちらかにこの行番号があれば、次のデータへ
        if debtors.first && debtors.first.line_number == line_number
          exists = true
          debtors.shift
        end
        if creditors.first && creditors.first.line_number == line_number
          exists = true
          creditors.shift
        end
        if exists
          # 存在したのであれば次の行番号を検査する
          line_number += 1
          next
        end
        # どちらにもこの行番号がなかったのであれば、残っているデータのline_numberをすべてひとつ小さくする
        # line_number が 負になるようだとプログラムエラー（無限ループ入り）なので念のため例外を発生させる
        debtors.each {|e| e.line_number -= 1; raise "Wrong Loop" if e.line_number < 0}
        creditors.each {|e| e.line_number -= 1;  raise "Wrong Loop" if e.line_number < 0}

        # もう一度同じ行番号で検査する
      end

      # 関連内の要素が直接書き変わっているはずなのであとは続く処理に任せる
    end
  end

  def set_creditor_to_entries
    debtor_entries.each {|e| e.creditor = false }
    creditor_entries.each {|e| e.creditor = true }
  end

  def copy_deal_info_to_entries
    each_entry {|e| copy_deal_info(e) }
  end

  def set_unified_summary
    each_entry {|e| e.summary = @unified_summary } if @unified_summary && @summary_mode == 'unify'
  end

  def each_entry(&block)
    debtor_entries.each(&block)
    creditor_entries.each(&block)
  end
end
