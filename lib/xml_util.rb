# -*- encoding : utf-8 -*-

class XMLUtil
  # Builderのエスケープを封じたので必要なものはここで
  def self.escape(text)
    if text
      text.gsub!(/&/, '&amp;')
      text.gsub!(/</, '&lt;')
      text.gsub!(/>/, '&gt;')
    end
    text
  end
end