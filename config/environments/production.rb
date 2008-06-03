# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors if you bad email addresses should just be ignored
# config.action_mailer.raise_delivery_errors = false


# Include your app's configuration here:
require 'error_handler_basic' # defines AC::Base#rescue_action_in_public


# 2.0対応時に動かなくなったのでコメントアウト
#class << Dispatcher
#  def dispatch(cgi = CGI.new,
#               session_options = ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS)
#    begin
#      request, response =
#        ActionController::CgiRequest.new(cgi, session_options),
#        ActionController::CgiResponse.new(cgi)
#      prepare_application
#      ActionController::Routing::Routes.recognize!(request).process(request, response).out
#    rescue Object => exception
#      begin
#        ActionController::Base.process_with_exception(request, response, exception).out
#      rescue ActionController::RoutingError
#        # pass
#      rescue ActionController::UnknownAction
#        # pass
#      rescue
#        # The rescue action above failed also, probably for the same reason
#        # the original action failed.  Do something simple which is unlikely
#        # to fail.  You might want to redirect to a static page instead of this.
#        e = exception
#        ExceptionMailer.deliver_emergency(e)
#
#        cgi.header("type" => "text/html")
#        cgi.out('cookie' => '') do
#          <<-RESPONSE
#    <html>
#      <head><title>Application Error</title></head>
#      <body>
#        <h1>Application Error</h1>
#        <b><pre>#{e.class}: #{e.message}</pre></b>
#
#        <pre>#{e.backtrace.join("\n")}</pre>
#      </body>
#    </html>
#        RESPONSE
#        end
#      end
#    ensure
#      reset_application
#    end
#  end
#end
