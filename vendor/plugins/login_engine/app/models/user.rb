class User < ActiveRecord::Base
  include LoginEngine::AuthenticatedUser

  # all logic has been moved into login_engine/lib/login_engine/authenticated_user.rb

end

