require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Kozuchi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    # Rails 8.0 デフォルトへの段階移行（全項目適用後に load_defaults 8.0 へ切替え予定）
    # Rails 8.1 で `to_time` がオフセットではなく完全なタイムゾーンを保持するようになる先取り対応
    config.active_support.to_time_preserves_timezone = :zone
    # Ruby YJIT を有効化（7.2 デフォルト・性能向上のみ）
    config.yjit = true

    config.active_record.belongs_to_required_by_default = false
    config.autoload_paths << "#{config.root}/lib"
    config.active_support.escape_html_entities_in_json = true
    config.active_record.schema_format = :sql
    config.active_record.observers = :user_observer
  end
end
