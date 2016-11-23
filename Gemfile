source 'http://rubygems.org'

gem 'rails', '4.0.2'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2', '~> 0.3.20' # TODO: Rails 4.2.5 以降でなおる

# gem 'prototype-rails', :git => 'git://github.com/rails/prototype-rails.git'
gem 'haml-rails'
gem 'bootstrap-sass'
gem 'html5jp_graphs', '~> 0.0.3'
gem 'dynamic_form'
gem 'therubyracer'
gem 'libv8', '~> 3.11.8.3'
gem 'passenger'
gem 'rb-readline'
gem 'httpclient'
gem 'jquery-rails'
gem 'sass', '3.2.6' # 3.2.7以上が入るとtravisでrequest specが失敗する
gem 'rails-observers' # TODO: なくしたい
gem 'activerecord-session_store'
group :assets do
  gem 'sass-rails', '~> 4.0.0'
  gem 'coffee-rails'
  gem 'uglifier', '>= 1.0.3'
end

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
# gem 'ruby-debug19'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
#  gem 'selenium-webdriver'
  gem 'i18n_generators'
  gem "rspec-rails", "~> 2.14"
  gem "capybara"
  gem 'poltergeist'
  gem "factory_girl_rails", "~> 4.0"
  gem "pry-rails"
end
