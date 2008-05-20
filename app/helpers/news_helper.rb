require "net/http"
require "rss"
module NewsHelper
  def news
    return '' unless defined?(NEWS_RSS_HOST) && !NEWS_RSS_HOST.blank? && defined?(NEWS_RSS_PATH) && !NEWS_RSS_PATH.blank?
    
    begin
      port = defined?(NEWS_RSS_PORT) ? NEWS_RSS_PORT : 80
      rss = RSS::Parser.parse(Net::HTTP.get(NEWS_RSS_HOST, NEWS_RSS_PATH, port))
      
      size = defined?(NEWS_RSS_SIZE) ? NEWS_RSS_SIZE : 3
      
      content = ""
      for i in 0...size
        item = rss.channel.items[i]
        break unless item
        content << "<h4>#{item.title} (#{item.pubDate.strftime("%Y/%m/%d")})</h4>"
        content << item.description
      end
      return content
    rescue
      return ''
    end
  end
end