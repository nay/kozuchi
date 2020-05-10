class ExportSweeper < ActionController::Caching::Sweeper
  observe Deal::Base, Account::Base, Settlement, User

  def self.key(format, user_id, host_with_port)
    "#{host_with_port}/export/whole/#{format.to_s}/whole-#{user_id}-#{format.to_s}"
  end

  def key(format, user_id)
    self.class.key(format, user_id, (controller && request) ? request.host_with_port : "no_host")
  end

  def after_save(record)
    expire(record) unless record.kind_of?(User)
  end
  
  def after_destroy(record)
    expire(record)
  end

  private
  def expire(record)
    return unless controller
    user_id = record.kind_of?(User) ? record.id : record.user_id
    expire_fragment(key(:xml, user_id))
    expire_fragment(key(:csv, user_id))
  end
end
