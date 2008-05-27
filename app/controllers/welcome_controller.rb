require 'rss'
class WelcomeController < ApplicationController
  skip_before_filter :login_required
    
  def index
    if !defined?(DISPLAY_NEWS) || DISPLAY_NEWS
      # newsキャッシュが昨日以前ならキャッシュを削除する（キャッシュ方式依存）
      file_path = File.join(RAILS_ROOT, "tmp/cache", fragment_cache_key(:action => 'news')) + ".cache"
      File.delete(file_path) if File.exist?(file_path) && File.mtime(file_path).to_date < Date.today
      
      # キャッシュがなければニュースを取ってくる。エラー時はnilが入るのでテンプレート側でキャッシュするかどうかを制御する。
      @news = File.exist?(file_path) ? true : news
    end
  end

  private
  
  # ニュースを取得する。取得できたニュースは同じ日に限りキャッシュする。
  def news
    return nil unless defined?(NEWS_RSS_HOST) && !NEWS_RSS_HOST.blank? && defined?(NEWS_RSS_PATH) && !NEWS_RSS_PATH.blank?
    
    begin
      port = defined?(NEWS_RSS_PORT) ? NEWS_RSS_PORT : 80
      timeout(5) do
        rss = RSS::Parser.parse(Net::HTTP.get(NEWS_RSS_HOST, NEWS_RSS_PATH, port))
        
        size = defined?(NEWS_RSS_SIZE) ? NEWS_RSS_SIZE : 3
        
        content = ""
        for i in 0...size
          item = rss.channel.items[i]
          break unless item
          content << "<h4>#{item.title} (#{item.pubDate.strftime('%Y/%m/%d')})</h4>"
          content << item.description
        end
        return content
      end
    rescue StandardError, TimeoutError => e
      logger.error "Could not get news."
      logger.error e
      return nil
    end    
  end
    
end
