# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.i18n.default_locale = 'ja'

  config.action_controller.session_store = :active_record_store
  config.active_record.observers = :user_observer
  config.action_mailer.smtp_settings = {
    :address        => "ko.meadowy.net",
    :port           => 25,
    :domain         => 'ko.meadowy.net',
    :user_name      => nil,
    :password       => nil,
    :authentication => nil
  } 
 config.action_controller.cache_store = :file_store, File.join(RAILS_ROOT, "tmp/cache")
end
