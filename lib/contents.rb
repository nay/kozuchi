module Contents
  def self.included(base)
    attr_accessor :show, :host, :path, :cache_expire_days, :cache_key, :body, :timeout_seconds
  end

  def get
    begin
      uri = URI.parse "#{host}#{path}"
      query = Hash[URI.decode_www_form(uri.query || "")]
      uri.query = URI.encode_www_form(query)
      client = HTTPClient.new
      resource = Timeout.timeout(timeout_seconds) do
        client.get(uri, follow_redirect: true)
      end
      Kozuchi.send("#{cache_key}_updated_on=", Time.zone.today)
      resource
    rescue StandardError, TimeoutError => e
      Rails.logger.error "Could not get #{self.class.name}."
      Rails.logger.error e
      nil
    end
  end

  def expired?
    return true unless cache_expire_days
    !Kozuchi.send("#{cache_key}_updated_on") || Kozuchi.send("#{cache_key}_updated_on") + (cache_expire_days - 1 ).days < Time.zone.today
  end

  def get_body!
    return unless show
    @body = get.try(:body)
  end
end
