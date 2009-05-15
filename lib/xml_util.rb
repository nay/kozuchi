class XMLUtil
  # Builderのエスケープを封じたので必要なものはここで
  def self.escape(text)
    text.gsub!(/&/, '&amp;')
    text.gsub!(/</, '&lt;')
    text.gsub!(/>/, '&gt;')
    text
  end
end