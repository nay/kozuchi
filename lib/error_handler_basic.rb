class ActionController::Base
  def rescue_action_in_public(exception)
    ExceptionMailer.deliver_emergency(exception)

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
