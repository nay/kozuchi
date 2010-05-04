ActionController::Routing::Routes.draw do |map|

  # settings
  map.namespace :settings do |settings|
    # 勘定
    settings.resources :incomes, :collection => {:update_all => :put}
    settings.resources :expenses, :collection => {:update_all => :put}
    settings.resources :assets, :collection => {:update_all => :put}

    # 連携
    settings.resources :account_link_requests, :as => :link_requests, :path_prefix => 'settings/accounts/:account_id', :only => [:destroy]
    # account_links
    settings.with_options :controller => 'account_links' do |account_links|
      # destroy に :id がいらない、create時はaccount_idをクエリーで渡したいなど変則的
      account_links.resource :account_link, :as => :links, :path_prefix => 'settings/accounts/:account_id', :only => [:destroy]
      account_links.resources :account_links, :as => :links, :path_prefix => 'settings/accounts', :only => [:index, :create]
    end
        # partner_accounts
    settings.with_options :controller => 'partner_accounts' do |partner_accounts|
      partner_accounts.resources :partner_accounts, :as => :partners, :path_prefix => 'settings/accounts', :only => [:index]
      partner_accounts.resource :partner_account, :as => :partner, :path_prefix => 'settings/accounts/:account_id', :only => [:update]
    end

    # フレンド
    settings.resource :friend_rejection, :as => :rejection, :path_prefix => "settings/friends/:target_login", :only => [:create, :destroy]
    settings.resource :friend_acceptance, :as => :acceptance, :path_prefix => "settings/friends", :only => [:create, :destroy] # createでは クエリーで target_login を渡したいため
    settings.resources :friends, :only => [:index]

    # カスタマイズ
    settings.resource :preferences, :only => [:show, :update]

    # シングルログイン
    settings.resources :single_logins, :only => [:index, :create, :destroy]
  end

  map.with_options :controller => 'deals' do |deals|
    deals.resources :deals, :only => [:edit, :update, :destroy], :member => {:confirm => :put}, :sub_resources => {:entries => {:only => [:create]}}

    deals.monthly_deals 'deals/:year/:month', :action => 'index',
      :requirements => {:year => /[0-9]*/, :month => /[0-9]*/}

    deals.general_deals 'general_deals', :action => 'create_general_deal', :conditions => {:method => :post}
    deals.balance_deals 'balance_deals', :action => 'create_balance_deal', :conditions => {:method => :post}
    deals.complex_deals 'complex_deals', :action => 'create_complex_deal', :conditions => {:method => :post}
    deals.new_general_deal 'general_deals/new', :action => 'new_general_deal', :conditions => {:method => :get}
    deals.new_balance_deal 'balance_deals/new', :action => 'new_balance_deal', :conditions => {:method => :get}
    deals.new_complex_deal 'complex_deals/new', :action => 'new_complex_deal', :conditions => {:method => :get}


    # TODO: 変更
  end


#  map.resources :general_deals


  map.resource :mobile_device, :member => {"confirm_destroy" => :get}, :controller => "mobiles"
#  map.mobile "/mobile", :controller => "mobiles", :action => "create_or_update", :codnitions => {:method => :put}
#  map.confirm_destroy_mobile "/mobile/confirm_destroy", :controller => "mobiles", :action => "confirm_destroy", :conditions => {:method => :get}
#  map.connect "/mobile", :controller => "mobiles", :action => "destroy", :conditions => {:method => :delete}
  
  map.home "/home", :controller => "home", :action => "index"

  map.signup '/signup', :controller => 'users', :action => 'new', :conditions => {:method => :get}
  map.signup_post '/signup', :controller => 'users', :action => 'create', :conditions => {:method => :post}

#  map.login '/login', :controller => 'sessions', :action => 'new'  , :conditions => {:method => :get}
  map.login_post '/login', :controller => 'sessions', :action => 'create', :conditions => {:method => :post}

  map.logout '/logout', :controller => 'sessions', :action => 'destroy'  
  map.single_login '/singe_login', :controller => 'sessions', :action => 'update', :conditions => {:method => :put}

  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate'

  # 互換性のため
  map.activate_login_engine '/user/home', :controller => 'users', :action => 'activate_login_engine'

  map.forgot_password '/forgot_password', :controller => 'users', :action => 'forgot_password'
  map.deliver_password_notification '/deliver_password_notification', :controller => 'users', :action => 'deliver_password_notification', :conditions => {:method => :post}
  map.password '/password/:password_token', :controller => 'users', :action => 'edit_password', :conditions => {:method => :get}
  map.password '/password/:password_token', :controller => 'users', :action => 'update_password', :conditions => {:method => :post}

  map.resource :user

  map.root :controller => "welcome"
  

  # Settlements
  map.resources :settlements, :collection => {:change_condition => :get}, :member => {:print_form => :get, :submit => :put}
#  map.connect 'settlement/:id/settlement.csv', :controller => 'settlements', :format => 'csv', :action => 'print_form'
#  map.connect 'settlement/:id', :controller => 'settlements', :action => 'view'
 # map.connect 'settlement/:id/:action', :controller => 'settlements'

  map.connect ':controller', :action => 'index', :conditions => {:method => :get}


  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # AccountDealsController
  # TODO: deal をつけるのがうざいがバッティングがあるためいったんつける
  map.with_options :controller => 'account_deals', :path_prefix => 'accounts/:account_id' do |account_deals|
    account_deals.account_deals 'deals/:year/:month', :action => 'monthly', :requirements => {:year => /[0-9]*/, :month => /[1-9]|10|11|12/}
    account_deals.account_balance 'balance', :action => "balance"
    account_deals.account_general_deals 'general_deals', :action => 'create_general_deal', :conditions => {:method => :post}
    ['creditor_general_deal', 'debtor_general_deal', 'balance_deal'].each do |deal_type|
      account_deals.send("account_#{deal_type.pluralize}", "#{deal_type.pluralize}", :action => "create_#{deal_type}", :conditions => {:method => :post})
      account_deals.send("new_account_#{deal_type}", "new_#{deal_type}", :action => "new_#{deal_type}", :conditions => {:method => :get})
      account_deals.send("edit_account_#{deal_type}", "#{deal_type.pluralize}/:id", :action => "edit_#{deal_type}", :conditions => {:method => :get})
    end
  end


  # deals, profit_and_loss
  map.connect ':controller/:year/:month', :action => 'index',
    :requirements => {:controller => /deals|profit_and_loss|assets|balance_sheet/,
                      :year => /[0-9]*/, :month => /[0-9]*/}

  map.daily_deals 'deals/:year/:month/:day', :action => 'daily', :controller => "deals"

  # daily summary
  map.daily_expenses ':year/:month/:day/expenses', :controller => "deals", :action => "expenses"
#  map.deal 'deals/:id', :controller => "deals", :action => "destroy", :conditions => {:method => :delete}


  map.with_options(:controller => "export") do |export|
    export.export 'export', :action => "index"
    export.export_file 'export/:filename.:format', :action => "whole"
  end

  # Install the default route as the lowest priority.
  # TODO: except sessions, 
  map.connect ':controller/:action/:id'
end
