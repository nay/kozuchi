source 'http://rubygems.org'
ruby '3.3.10'

gem 'activerecord-session_store'
gem 'bootstrap-sass'
gem 'haml-rails'
gem 'httpclient'
gem 'passenger'
gem 'pg'
gem 'sassc-rails'
gem 'concurrent-ruby'
gem 'rails', '~> 7.2.3'
gem 'rails-controller-testing'
gem 'rails-observers'
gem 'rake'
gem 'rails_autolink'
gem 'jsbundling-rails'
gem 'puma'


# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem "capybara"
  gem 'capybara-screenshot'
  gem 'database_cleaner'
  gem "factory_bot_rails"
  gem 'i18n_generators'
  gem 'listen'
  gem 'cuprite'
  gem "pry-rails"
  gem "rspec-rails"
  gem 'timecop'
end

group :production do
  gem 'sendgrid-ruby'
end
