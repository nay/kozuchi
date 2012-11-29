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
