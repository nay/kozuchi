# -*- encoding : utf-8 -*-
module Deal

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
    base.before_save :adjust_entry_line_numbers

    base.class_eval do
      [:debtor, :creditor].each do |side|
        define_method :"#{side}_entries_attributes_with_account_care=" do |attributes|
          # 金額も口座IDも摘要も入っていないentry情報は無視する
          attributes = attributes.values if attributes.kind_of?(Hash)
          attributes.reject!{|value| value[:amount].blank? && value[:reversed_amount].blank? && value[:account_id].blank? && value[:summary].blank?}

          # 更新時は必ずしも ID ではなく、内容で既存のデータと紐づける
          unless new_record?
            old_entries = Array.new(send(:"#{side}_entries", true))

            # attirbutes の中と引き当てていく
            matched_old_entries = []
            matched_new_entries = []
            old_entries.each do |old|
              if matched_hash = attributes.detect{|new_entry_hash| old.matched_with_attributes?(new_entry_hash) }
                matched_hash[:id] = old.id.to_s # IDを付け替える
                matched_old_entries << old
                matched_new_entries << matched_hash
              end
            end
            not_matched_new_entries = attributes - matched_new_entries
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
          send(:"#{side}_entries_attributes_without_account_care=", attributes)
        end

        alias_method_chain :"#{side}_entries_attributes=", :account_care
      end
    end

  end

  def load(from)
    self.debtor_entries_attributes = from.debtor_entries.map(&:copyable_attributes) #{|e| {:account_id => e.account_id, :amount => e.amount, :summary => e.summary}}
    self.creditor_entries_attributes = from.creditor_entries.map(&:copyable_attributes) #{|e| {:account_id => e.account_id, :amount => e.amount, :summary => e.summary}}
    self
  end

  def copy_deal_info(entry)
    entry.user_id = user_id
    entry
  end

  def summary_unified?
    summary_mode != 'split' && (debtor_entries.map(&:summary) + creditor_entries.map(&:summary)).find_all{|s| !s.blank?}.uniq.size == 1
  end

  def summary=(s)
    @unified_summary = s
  end

  def summary
    @unified_summary || (debtor_entries + creditor_entries).detect{|e| e.summary.present?}.try(:summary) || ''
  end

  def reload
    @unified_summary = nil
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

  private

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
      raise "Duplicated line number in debtor entries. #{debtor_entries.inspect}" if debtors.map(&:line_number).uniq.size != debtors.size
      raise "Duplicated line number in creditor entries. #{debtor_entries.inspect}" if creditors.map(&:line_number).uniq.size != creditors.size

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
