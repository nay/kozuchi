require 'rubygems'
require 'action_controller'


#require 'action_controller/cgi_ext'
# require 'action_controller/test_process'
# require 'action_view/test_case'

# Show backtraces for deprecated behavior for quicker cleanup.
# ActiveSupport::Deprecation.debug = true

#ActionController::Base.logger = nil
ActionController::Routing::Routes.reload rescue nil

#ActionController::Base.session_store = nil

# Register danish language for testing
# I18n.backend.store_translations 'da', {}
# I18n.backend.store_translations 'pt-BR', {}
# ORIGINAL_LOCALES = I18n.available_locales.map(&:to_s).sort

# FIXTURE_LOAD_PATH = File.join(File.dirname(__FILE__), 'fixtures')
# ActionView::Base.cache_template_loading = true
# ActionController::Base.view_paths = FIXTURE_LOAD_PATH
# CACHED_VIEW_PATHS = ActionView::Base.cache_template_loading? ?
#                      ActionController::Base.view_paths :
#                      ActionController::Base.view_paths.map {|path| ActionView::Template::EagerPath.new(path.to_s)}


require 'action_controller/resources'
#require 'action_controller/routing/optimisation'
require 'action_controller/routing/route_set'

#ENV["RAILS_ENV"] ||= 'test'
#require File.expand_path(File.join(File.dirname(__FILE__),'..','config','environment'))
#require 'spec'
#$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib')))
require 'sub_resources'

