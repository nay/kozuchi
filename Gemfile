source 'http://rubygems.org'
ruby '4.0.7'

# 2.3.0 では、セッションの中のハッシュを直接書き換えた変更が保存されない（表示した年月がセッションに残らない）ため、2.2 系に留める
# https://github.com/rails/activerecord-session_store/issues/236 が直ったら外す
gem 'activerecord-session_store', '< 2.3'
gem 'bootstrap-sass'
gem 'haml-rails'
gem 'httpclient'
gem 'passenger'
gem 'pg'
gem 'sassc-rails'
gem 'concurrent-ruby'
gem 'rails', '~> 8.1.0'
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
