YEAR_MONTH_REQUIREMENTS = {:year => /[0-9]*|_YEAR_/, :month => /[1-9]|10|11|12|_MONTH_/}
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

  # DealsController
  map.with_options :controller => 'deals' do |deals|
    deals.resources :deals, :only => [:edit, :update, :destroy], :member => {:confirm => :put}, :sub_resources => {:entries => {:only => [:create]}}

    deals.general_deals 'general_deals', :action => 'create_general_deal', :conditions => {:method => :post}
    deals.balance_deals 'balance_deals', :action => 'create_balance_deal', :conditions => {:method => :post}
    deals.complex_deals 'complex_deals', :action => 'create_complex_deal', :conditions => {:method => :post}
    deals.new_general_deal 'general_deals/new', :action => 'new_general_deal', :conditions => {:method => :get}
    deals.new_balance_deal 'balance_deals/new', :action => 'new_balance_deal', :conditions => {:method => :get}
    deals.new_complex_deal 'complex_deals/new', :action => 'new_complex_deal', :conditions => {:method => :get}

#    deals.resources :deals
    deals.monthly_deals 'deals/:year/:month', :action => 'monthly', :conditions => {:method => :get}, :requirements => YEAR_MONTH_REQUIREMENTS
    # TODO: 変更
  end

  # DealSuggestionsController
  map.resources :deal_suggestions, :as => :suggestions, :path_prefix => 'deals', :only => [:index]



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
  

  # SettlementsController
  map.with_options :controller => 'settlements' do |settlements|
    settlements.new_settlement_target_deals 'settlements/new/target_deals', :action => :target_deals, :conditions => {:method => :get}
    settlements.resources :settlements, :only => [:index, :show, :new, :create, :destroy],
      :member => {:print_form => :get, :submit => :put}
  end
  # AccountDealsController
  # TODO: deal をつけるのがうざいがバッティングがあるためいったんつける
  map.with_options :controller => 'account_deals' do |account_deals|
    account_deals.resources :account_deals, :as => :deals, :path_prefix => 'accounts', :only => [:index]
    account_deals.with_options :path_prefix => 'accounts/:account_id' do |under_account|
      under_account.monthly_account_deals 'deals/:year/:month', :action => 'monthly', :requirements => YEAR_MONTH_REQUIREMENTS
      under_account.account_balance 'balance', :action => "balance"
      under_account.account_general_deals 'general_deals', :action => 'create_general_deal', :conditions => {:method => :post}
      ['creditor_general_deal', 'debtor_general_deal', 'balance_deal'].each do |deal_type|
        under_account.send("account_#{deal_type.pluralize}", "#{deal_type.pluralize}", :action => "create_#{deal_type}", :conditions => {:method => :post})
        under_account.send("new_account_#{deal_type}", "new_#{deal_type}", :action => "new_#{deal_type}", :conditions => {:method => :get})
        under_account.send("edit_account_#{deal_type}", "#{deal_type.pluralize}/:id", :action => "edit_#{deal_type}", :conditions => {:method => :get})
      end
    end
  end

  # AssetsController
  map.with_options :controller => 'assets' do |assets|
    assets.resources :assets, :only => [:index]
    assets.monthly_assets 'assets/:year/:month', :action => 'monthly', :requirements => YEAR_MONTH_REQUIREMENTS
  end

  # BalanceSheetController
  map.with_options :controller => 'balance_sheet' do |balance_sheet|
    balance_sheet.resource :balance_sheet, :only => [:show]
    balance_sheet.monthly_balance_sheet 'balance_sheet/:year/:month', :action => 'monthly', :requirements => YEAR_MONTH_REQUIREMENTS
  end

  # ProfitAndLossController
  map.with_options :controller => 'profit_and_loss' do |profit_and_loss|
    profit_and_loss.resource :profit_and_loss, :only => [:show]
    profit_and_loss.monthly_profit_and_loss 'profit_and_loss/:year/:month', :action => 'monthly', :requirements => YEAR_MONTH_REQUIREMENTS
  end

  # MobileDealsController
  map.with_options :controller => 'mobile_deals', :path_prefix => 'mobile' do |mobile_deals|
    mobile_deals.mobile_daily_expenses 'expenses/:year/:month/:day', :action => 'daily_expenses', :conditions => {:method => :get}
    mobile_deals.new_mobile_general_deal 'deals/general/new', :action => 'new_general_deal', :conditions => {:method => :get}
    mobile_deals.mobile_general_deals 'deals/general', :action => 'create_general_deal', :conditions => {:method => :post}
    mobile_deals.daily_created_mobile_deals 'deals/created/:year/:month/:day', :action => 'daily_created', :conditions => {:method => :get}
  end

  # ExportController
  map.with_options(:controller => "export") do |export|
    export.export 'export', :action => "index"
    export.export_file 'export/:filename.:format', :action => "whole"
  end

  # HelpController
  map.connect 'help/:action', :controller => 'help'

  # Install the default route as the lowest priority.
  # TODO: except sessions, 
  map.connect ':controller/:action/:id'
end
