require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Kozuchi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

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
