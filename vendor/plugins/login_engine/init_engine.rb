# load up all the required files we need...

require 'login_engine'

module LoginEngine::Version
  Major = 1
  Minor = 0
  Release = 2
end

Engines.current.version = LoginEngine::Version