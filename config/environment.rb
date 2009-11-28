# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug
  # config.log_level = :warn

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store
  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  config.active_record.observers = :user_observer

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
 
#  config.action_mailer.default_charset = 'iso-2022-jp' 
  config.action_mailer.smtp_settings = {
    :address        => "ko.meadowy.net",
    :port           => 25,
    :domain         => 'ko.meadowy.net',
    :user_name      => nil,
    :password       => nil,
    :authentication => nil
  } 
#  config.action_mailer.delivery_method = :sendmail
#  config.action_mailer.sendmail_settings = {
#    :location => '/foo',
#    :arguments => '-i'
#  }
#  config.action_mailer.smtp_settings = {:address => "192.168.0.102"}

 config.action_controller.cache_store = :file_store, File.join(RAILS_ROOT, "tmp/cache")
# config.action_controller.fragment_cache_store = :file_store, File.join(RAILS_ROOT, "tmp/cache")
end
