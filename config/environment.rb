# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.0.2' unless defined? RAILS_GEM_VERSION

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

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_kozuchi_session',
    :secret      => '7d21d9d42b01d956fd2998c9418d022cb0183e6be01718553259007a21a0a700b5858352374789a4b9adfe738ec92de4d18af69ebbb79b54a9bd70f27a782088'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
#  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
 
  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.sendmail_settings = {
    :location => '/foo',
    :arguments => '-i'
  }
#  config.action_mailer.smtp_settings = {:address => "192.168.0.102"}
  config.action_mailer.default_charset = 'iso-2022-jp'
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below
#ActionController::AbstractRequest.relative_url_root = '/kozuchi'

KOZUCHI_SSL = false

# USER_MANAGEMENT_TYPE
#   open : Anybody can make new user.
#   closed : Admin function only.
KOZUCHI_USER_MANAGEMENT_TYPE = 'open'

# GOOGLE_ANALYTICS_CODE = 'XXXXXX-X'

#module LoginEngine
#  config :salt, "koban"
#  config :email_from, "kozuchi@goas.no-ip.org"
#  config :admin_email, "kozuchi@goas.no-ip.org"
#  config :app_name, "小槌"
#  config :changeable_fields, ['lastname', 'firstname', 'login', 'email']
#  config :mail_charset, "iso-2022-jp"
##  config :use_email_notification, false
#end
#ActionMailer::Base.default_charset = 'iso-2022-jp'
#
#Engines.start :login
