require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Kozuchi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Rails 8.1 デフォルトへの段階移行（全項目適用後に load_defaults 8.1 へ切替え予定）
    # development と test では YJIT を無効化（8.1 デフォルト。production は有効のまま）
    config.yjit = !Rails.env.local?
    # render json: のレスポンスで HTML エンティティ等をエスケープしない（8.1 デフォルト）
    config.action_controller.escape_json_responses = false
    # JSON で U+2028 / U+2029 をエスケープしない（8.1 デフォルト）
    config.active_support.escape_js_separators_in_json = false
    # 並び順を決められない first / last などを例外にする（8.1 デフォルト）
    config.active_record.raise_on_missing_required_finder_order_columns = true
    # スラッシュで始まらない相対パスへのリダイレクトを例外にする（8.1 デフォルト）
    config.action_controller.action_on_path_relative_redirect = :raise
    # テンプレートの依存関係を Ruby パーサで解析する（8.1 デフォルト）
    config.action_view.render_tracker = :ruby

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.active_record.belongs_to_required_by_default = false
    config.autoload_paths << "#{config.root}/lib"
    config.active_support.escape_html_entities_in_json = true
    config.active_record.schema_format = :sql
    config.active_record.observers = :user_observer

    # config.time_zone は framework の初期化中に消費されるため、
    # config/initializers 以下に書いても反映されない。ここに書く必要がある
    config.time_zone = 'Tokyo'
    config.i18n.default_locale = 'ja'
  end
end
