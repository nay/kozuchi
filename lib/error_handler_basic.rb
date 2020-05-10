class ActionController::Base
  def rescue_action_in_public(exception)
    return if exception.kind_of?( ActionController::RoutingError )
    return if exception.kind_of?( ActionController::UnknownAction )

    redirect_to(:controller => 'user', :action => 'home')
#    render :text => <<END
#<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
#<html>
#<head>
#<body>
#
##{exception.backtrace.join("\n")}
#</body></html>
#END
  end  
end
