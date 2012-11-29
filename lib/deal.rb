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
  end

  def copy_deal_info(entry)
    entry.user_id = user_id
    entry
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
