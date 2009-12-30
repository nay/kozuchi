# ネストした属性を正しく表示するため上書きする
module ActiveRecord
  class Errors
    def full_messages(options = {})
      result = []
      each_error do |key, error|
        words = key.to_s.split('.')
        words.pop
        upper_attribute = words.first
        result <<
          if !upper_attribute.blank?
            @base.class.human_attribute_name(upper_attribute) + 'の' + error.full_message
          else
            error.full_message
          end
      end
      result
    end
  end
end