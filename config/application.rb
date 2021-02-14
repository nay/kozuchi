require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Kozuchi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.active_record.belongs_to_required_by_default = false
    config.eager_load_paths += %W(#{config.root}/lib)
    config.active_support.escape_html_entities_in_json = true
    config.active_record.schema_format = :sql
    config.active_record.observers = :user_observer
  end
end
