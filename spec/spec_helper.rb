# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'database_cleaner'
DatabaseCleaner.strategy = :truncation

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = true

  config.before(:all) do
    self.class.set_fixture_class accounts:           Account::Base,
                                 deals:              Deal::Base,
                                 friend_requests:    Friend::Request,
                                 friend_permissions: Friend::Permission,
                                 preferences:        Preferences
  end

  config.before(:each) do |example|
    if example.metadata[:js]
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
    end
    DatabaseCleaner.start
  end

  config.after(:each) do |example|
    DatabaseCleaner.clean
  end

end

def to_sjis(str)
  str.encode("Shift_JIS", "UTF-8")
end


class Symbol
  def to_id
    Fixtures.identify(self)
  end
end

# class ActionController::TestRequest
#   def session_options_with_session_key
#     {:key => '_session_id'}.merge(session_options_without_session_key)
#   end
#   alias_method_chain :session_options, :session_key
# end

require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist

require 'capybara-screenshot/rspec'
