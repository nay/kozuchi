# -*- encoding : utf-8 -*-
require 'rss'
require 'net/http'
class WelcomeController < ApplicationController
  skip_before_filter :login_required
    
  def index
    if !request.mobile? && (!defined?(DISPLAY_NEWS) || DISPLAY_NEWS)
      # ファイルが存在したまま再起動するとnilになるのでそのときも expire でカバーする
      if !Kozuchi.news_updated_on || Kozuchi.news_updated_on < Date.today
        expire_fragment(:action_suffix => 'news')
      end
      
      # キャッシュがなければニュースを取ってくる。エラー時はnilが入るのでテンプレート側でキャッシュするかどうかを制御する。
      @news = fragment_exist?(:action_suffix => 'news') ? true : news.to_s.html_safe
    end
    # ログインしておらず、携帯からのアクセスの場合は、簡単ログインを試みる
    if !current_user || request.mobile?

    end
  end

  private
  
  # ニュースを取得する。取得できたニュースは同じ日に限りキャッシュする。
  def news
    return nil unless defined?(NEWS_RSS_HOST) && !NEWS_RSS_HOST.blank? && defined?(NEWS_RSS_PATH) && !NEWS_RSS_PATH.blank?
    begin
      logger.info "Started to get the news from #{NEWS_RSS_HOST}."
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
        Kozuchi.news_updated_on = Date.today
        return content
      end
    rescue StandardError, TimeoutError => e
      logger.error "Could not get news."
      logger.error e
      return nil
    end    
  end
    
end
