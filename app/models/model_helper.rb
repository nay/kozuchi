module ModelHelper
  # DB実装によってSQL用の判定値を切り替える。ActiveRecord 側に実装があるならそちらを使いたいが見つからないので。
  def boolean_to_s(b)
    adapter_name = self.connection.adapter_name
    
    case self.connection.adapter_name
    when 'MySQL'
      return b ? 1 : 0
    when 'SQLite'
      return b ? "'t'" : "'f'"
    else
      self.logger.warn("ModelHelper.boolean_to_s was invoked when you used unsupported database adapater #{self.connection.adapter_name}. Guessed boolean value should be 0 or 1.")
      return b ? 1 : 0
    end
  end
end