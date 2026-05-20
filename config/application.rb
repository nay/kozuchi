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
    # マイグレーションのタイムスタンプを検証（7.2 デフォルト）
    config.active_record.validate_migration_timestamps = true
    # Active Storage のバリアント対象 web 画像タイプ（7.2 デフォルト）
    config.active_storage.web_image_content_types = %w[image/png image/jpeg image/gif image/webp]
    # 条件付きGETで If-None-Match と If-Modified-Since 併用時 RFC 7232 に従い ETag を優先（8.0 デフォルト）
    config.action_dispatch.strict_freshness = true

    config.active_record.belongs_to_required_by_default = false
    config.autoload_paths << "#{config.root}/lib"
    config.active_support.escape_html_entities_in_json = true
    config.active_record.schema_format = :sql
    config.active_record.observers = :user_observer
  end
end
