class ExportSweeper < ActionController::Caching::Sweeper
  observe Deal, Account::Base, Settlement, User

  def self.key(format, user_id)
    "export/whole/#{format.to_s}/whole-#{user_id}-#{format.to_s}"
  end

  def after_save(record)
    expire(record) unless record.kind_of?(User)
  end
  
  def after_destroy(record)
    expire(record)
  end

  private
  def expire(record)
    user_id = record.kind_of?(User) ? record.id : record.user_id
    expire_fragment(self.class.key(:xml, user_id))
    expire_fragment(self.class.key(:csv, user_id))
  end
end
