ActionController::Routing::Routes.draw do |map|

  map.signup '/signup', :controller => 'users', :action => 'new', :conditions => {:method => :get}
  map.signup_post '/signup', :controller => 'users', :action => 'create', :conditions => {:method => :post}

#  map.login '/login', :controller => 'sessions', :action => 'new'  , :conditions => {:method => :get}
  map.login_post '/login', :controller => 'sessions', :action => 'create', :conditions => {:method => :post}

  map.logout '/logout', :controller => 'sessions', :action => 'destroy'  
  
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate'

  # 互換性のため
  map.activate_login_engine '/user/home', :controller => 'users', :action => 'activate_login_engine'

  map.forgot_password '/forgot_password', :controller => 'users', :action => 'forgot_password'
  map.deliver_password_notification '/deliver_password_notification', :controller => 'users', :action => 'deliver_password_notification', :conditions => {:method => :post}
  map.password '/password/:password_token', :controller => 'users', :action => 'edit_password', :conditions => {:method => :get}
  map.password '/password/:password_token', :controller => 'users', :action => 'update_password', :conditions => {:method => :post}

  map.resource :user
  
#  map.resource :session

  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  map.root :controller => "welcome"
  
  map.connect 'admin/:action', :controller => "admin/admin"

  map.connect ':controller', :action => 'index'
  
#  map.connect 'settlement/:id/settlement.csv', :controller => 'settlements', :format => 'csv', :action => 'print_form'
  map.connect 'settlement/:id', :controller => 'settlements', :action => 'view'
  map.connect 'settlement/:id/:action', :controller => 'settlements'

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # account_deals
  map.account_deals 'accounts/:account_id/deals/:year/:month', :action => 'monthly', :controller => 'account_deals', :requirements => {:year => /[0-9]*/, :month => /[1-9]|10|11|12/}

  # deals, profit_and_loss
  map.connect ':controller/:year/:month', :action => 'index',
    :requirements => {:controller => /deals|profit_and_loss|assets|balance_sheet/,
                      :year => /[0-9]*/, :month => /[0-9]*/}
  
  # Install the default route as the lowest priority.
  # TODO: except sessions, 
  map.connect ':controller/:action/:id'
  map.connect ':controller/:year/:month/:day', :action => 'index', :requirements => {:controller => /daily_booking/}
end
