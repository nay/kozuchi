# -*- encoding : utf-8 -*-
require 'rss'
require 'net/http'

class News
  cattr_accessor :rss_host, :rss_path, :rss_port, :size

  self.rss_host = "www.kozuchi.net"
  self.rss_path = "/rss"
  self.rss_port = 80
  self.size = 3

  # ニュースを取得する。エラーで取得できなかったときはnilを返す。
  def self.get
    begin
      Rails.logger.info "Started to get the news from #{rss_host}."
      Timeout.timeout(5) do
        rss = RSS::Parser.parse(Net::HTTP.get(rss_host, rss_path, rss_port))

        content = ""
        for i in 0...size
          item = rss.channel.items[i]
          break unless item
          content << "<h4>#{item.title} (#{item.pubDate.strftime('%Y/%m/%d')})</h4>"
          content << item.description
        end
        Kozuchi.news_updated_on = Time.zone.today
        content
      end
    rescue StandardError, TimeoutError => e
      Rails.logger.error "Could not get news."
      Rails.logger.error e
      nil
    end
  end

end
