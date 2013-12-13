# -*- encoding : utf-8 -*-
module Contents
  TIMEOUT_SCONDS = 20
  def self.included(base)
    attr_accessor :host, :path, :port, :cache_expire_days, :cache_key, :body
  end

  def get
    begin
      uri = URI.parse "#{host}#{path}"
      query = Hash[URI.decode_www_form(uri.query || "")]
      uri.query = URI.encode_www_form(query)
      client = HTTPClient.new
      resource = timeout(TIMEOUT_SCONDS) do
        client.get(uri, follow_redirect: true)
      end
      Kozuchi.send("#{cache_key}_updated_on=", Date.today)
      resource
    rescue StandardError, TimeoutErro=> e
      Rails.logger.error "Could not get #{self.class.name}."
      Rails.logger.error e
      nil
    end
  end

  def expired?
    return true unless cache_expire_days
    !Kozuchi.send("#{cache_key}_updated_on") || Kozuchi.send("#{cache_key}_updated_on")  + (cache_expire_days - 1 ).days < Date.today
  end

  def get_body!
    self.body = get.try(:body)
  end
end
