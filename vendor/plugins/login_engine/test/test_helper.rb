require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper') # the default rails helper

# ensure that the Engines testing enhancements are loaded.
require File.join(Engines.config(:root), "engines", "lib", "engines", "testing_extensions")

require File.dirname(__FILE__) + '/mocks/time'
require File.dirname(__FILE__) + '/mocks/mail'

# set up the fixtures location
Test::Unit::TestCase.fixture_path = File.dirname(__FILE__)  + "/fixtures/"
$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)
