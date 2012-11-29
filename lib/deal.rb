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

  def self.included(base)
    base.accepts_nested_attributes_for :debtor_entries, :creditor_entries, :allow_destroy => true
    base.before_validation :copy_deal_info_to_entries, :set_creditor_to_entries
  end

  def copy_deal_info(entry)
    entry.user_id = user_id
    entry
  end

  private
  def set_creditor_to_entries
    debtor_entries.each {|e| e.creditor = false}
    creditor_entries.each {|e| e.creditor = true}
  end

  def copy_deal_info_to_entries
    creditor_entries.each {|e| copy_deal_info(e) }
    debtor_entries.each {|e| copy_deal_info(e) }
  end

end
