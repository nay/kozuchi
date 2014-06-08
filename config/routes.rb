YEAR_MONTH_REQUIREMENTS = {:year => /[0-9]*|_YEAR_/, :month => /[1-9]|10|11|12|_MONTH_/}

Kozuchi::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # settings
  namespace :settings do
    controller :incomes do
      put 'incomes', :action => :update_all
      resources :incomes
    end
    controller :expenses do
      put 'expenses', :action => :update_all
      resources :expenses
    end
    controller :assets do
      put 'assets', :action => :update_all
      resources :assets
    end
    # 連携
    resources :account_link_requests, :path => 'accounts/:account_id/link_requests', :only => [:destroy]

    # account_links
    scope :controller => :account_links, :path => 'accounts' do
    # destroy に :id がいらない、create時はaccount_idをクエリーで渡したいなど変則的
      scope :path => ':account_id' do
        resource :account_link, :path => :links, :only => [:destroy]
      end
      resources :account_links, :path => :links, :only => [:index, :create]
    end

    # partner_accounts
    scope :controller => :partner_accounts, :path => 'accounts' do
      resources :partner_accounts, :path => :partners, :only => [:index]
      resource :partner_account, :path => ':account_id/partner', :only => [:update]
    end

    # フレンド
    resource :friend_rejection, :path => 'friends/:target_login/rejection', :only => [:create, :destroy]
    resource :friend_acceptance, :path => "friends/acceptance", :only => [:create, :destroy] # createでは クエリーで target_login を渡したいため
    resources :friends, :only => [:index]

    # 記入パターン
    controller :deal_patterns do
      resources :deal_patterns, :path => 'deals/patterns'
      match 'deals/patterns/:id/entries', :action => 'create_entry', :as => :deal_pattern_entries, :via => [:post, :patch]
      get 'deals/patterns/codes/:code', :action => 'code', :as => :deal_pattern_codes
    end

    # カスタマイズ
    resource :preferences, :only => [:show, :update]

    # シングルログイン
    resources :single_logins, :only => [:index, :create, :destroy]
  end

  # DealPatternsController
  controller :deal_patterns do
    get 'deals/patterns/recent', :action => 'recent', :as => 'recent_deal_patterns'
    resources :deal_patterns, :path => 'deals/patterns', :only => [:create]
  end

  # DealsController
  controller :deals do
    resources :deals, :only => [:index, :edit, :update, :destroy, :new] do
      member do
        put 'confirm'
      end
      collection do
        get 'search'
      end
    end
    # :sub_resources => {:entries => {:only => [:create]}}
    # postだけにしたいが構造上 put のフォームの中から呼ばれて面倒なので
    match 'deals/:id/entries', :action => 'create_entry', :as => :deal_entries, :via => [:post, :patch]

    ['general', 'balance', 'complex'].each do |t|
      post "#{t}_deals", :action => "create_#{t}_deal", :as => :"#{t}_deals"
      get "#{t}_deals/new", :action => "new_#{t}_deal", :as => :"new_#{t}_deal"
    end

    get 'deals/:year/:month/days', :as => :monthly_deal_days, :action => 'day_navigator'
    # TODO: なぜか page.redirect_to redirect_options_proc.call(@deal) でrequirements があるとうまくいかない
    get 'deals/:year/:month', :as => :monthly_deals, :action => 'monthly' #, :requirements => YEAR_MONTH_REQUIREMENTS
  end

  # DealSuggestionsController
  resources :deal_suggestions, :path => 'deals/suggestions', :only => [:index]

  resource :mobile_device, :controller => :mobiles do
    member do
      get 'confirm_destroy'
    end
  end

  get '/home' => 'home#index', :as => :home

  resource :user

  # SettlementsController
  controller :settlements do
    get 'settlements/new/target_deals', :as => :new_settlement_target_deals, :action => :target_deals
    get 'settlements/accounts/:account_id', :as => :account_settlements, :action => :index
    resources :settlements, :only => [:index, :show, :new, :create, :destroy] do
      member do
        get 'print_form'
        put 'submit'
      end
    end
  end

  # AccountDealsController
  # TODO: deal をつけるのがうざいがバッティングがあるためいったんつける
  controller :account_deals do
    resources :account_deals, :path => 'accounts/deals', :only => [:index]
    scope :path => 'accounts/:account_id' do
      get 'deals/:year/:month', :as => :monthly_account_deals, :action => 'monthly'# TODO: なぜかあるとうまくいかない, :requirements => YEAR_MONTH_REQUIREMENTS
      get 'balance', :as => :account_balance, :action => :balance
      post 'general_deals', :as => :account_general_deals, :action => 'create_general_deal'
      ['creditor_general_deal', 'debtor_general_deal', 'balance_deal'].each do |t|
        post "#{t.pluralize}", :as => "account_#{t.pluralize}", :action => "create_#{t}"
        get "new_#{t}", :as => "new_account_#{t}", :action => "new_#{t}"
        get "#{t.pluralize}/:id", :as => "edit_account_#{t}", :action => "edit_#{t}"
      end
    end
  end

  # AssetsController
  controller :assets, :path => 'f' do # /assets はじまりは無視されるため
    get 'assets/:year/:month', {:as => :monthly_assets, :action => :monthly}.merge(YEAR_MONTH_REQUIREMENTS)
    resources :assets, :only => [:index]
  end

  # BalanceSheetController
  controller :balance_sheet do
    get :balance_sheet, :action => :show
    get 'balance_sheet/:year/:month', {:as => :monthly_balance_sheet, :action => 'monthly'}.merge(YEAR_MONTH_REQUIREMENTS)
  end

  # ProfitAndLossController
  controller :profit_and_loss do
    get :profit_and_loss, :action => :show
    get 'profit_and_loss/:year/:month', {:as => :monthly_profit_and_loss, :action => 'monthly'}.merge(YEAR_MONTH_REQUIREMENTS)
  end

  # MobileDealsController
  scope :controller => 'mobile_deals', :path => 'mobile' do
    get 'expenses/:year/:month/:day', :as => :mobile_daily_expenses, :action => 'daily_expenses'
    get 'deals/general/new', :as => :new_mobile_general_deal, :action => 'new_general_deal'
    post 'deals/general', :as => :mobile_general_deals, :action => 'create_general_deal'
    get 'deals/created/:year/:month/:day', :as => :daily_created_mobile_deals, :action => 'daily_created'
  end

  # ExportController
  controller :export do
    get 'export', :as => :export, :action => "index"
    get 'export/:filename.:format', :as => :export_file, :action => "whole"
  end

  # HelpController
  controller :help do
    get 'help/:action'
  end

#  # TODO: except sessions,
#  map.connect ':controller/:action/:id'

  root :to => "welcome#index"

  get '/signup' => 'users#new', :as => :signup, :via => :get
  match '/signup' => 'users#create', :as => :signup_post, :via => :post # TODO: must be unified to signup
  match '/login' => 'sessions#create', :as => :login_post, :via => :post # TODO: change to login
  match '/logout' => 'sessions#destroy', :as => :logout, :via => :delete
  match '/singe_login' => 'sessions#update', :as => :single_login, :via => :put
  get '/activate/:activation_code' => 'users#activate', :as => :activate
  match '/privacy_policy' => 'users#privacy_policy', :as => :privacy_policy, :via => :get

  # 互換性のため
  # TODO: さすがにそろそろ消してよいでしょう
  get '/user/home' => 'users#activate_login_engine', :as => :activate_login_engine

  get '/forgot_password' => 'users#forgot_password', :as => :forgot_password
  match  '/deliver_password_notification' => 'users#deliver_password_notification', :via => :post, :as => :deliver_password_notification
  match '/password/:password_token' => 'users#edit_password', :via => :get, :as => :password
  match '/password/:password_token' => 'users#update_password', :via => :post
end
