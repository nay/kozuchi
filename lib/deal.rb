module Deal
  def self.included(base)
    base.before_validation :set_creditor_to_entries
  end

  private
  def set_creditor_to_entries
    debtor_entries.each {|e| e.creditor = false}
    creditor_entries.each {|e| e.creditor = true}
  end
  
end
