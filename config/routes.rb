YEAR_MONTH_REQUIREMENTS = {:year => /[0-9]*|_YEAR_/, :month => /[1-9]|10|11|12|_MONTH_/}

Rails.application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # settings
  namespace :settings do
    controller :accounts do
      %w(asset income expense).each do |type|
        with_options account_type: type do |with_type|
          with_type.put type.pluralize, :action => :update_all
          with_type.resources type.pluralize, controller: :accounts, only: [:index, :show, :create, :update, :destroy]
        end
      end
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
    resources :deals, :only => [:index, :edit, :update, :destroy] do
      member do
        put 'confirm'
      end
      collection do
        get 'search'
      end
    end
    get 'deals/:id/edit/deal_pattern/:pattern_code', as: :deal_pattern_in_edit, action: :load_deal_pattern_into_edit
    # :sub_resources => {:entries => {:only => [:create]}}
    # postだけにしたいが構造上 put のフォームの中から呼ばれて面倒なので
    match 'deals/:id/entries', :action => 'create_entry', :as => :deal_entries, :via => [:post, :patch]

    ['general', 'balance', 'complex'].each do |t|
      post "#{t}_deals", :action => "create_#{t}_deal", :as => :"#{t}_deals"
      get "#{t}_deals/new", :action => "new_#{t}_deal", :as => :"new_#{t}_deal"
      post "accounts/:account_id/#{t}_deals", :action => "create_#{t}_deal", :as => :"account_#{t}_deals"
      get "accounts/:account_id/#{t}_deals/new", :action => "new_#{t}_deal", :as => :"new_account_#{t}_deal"
    end

    get 'deals/:year/:month/days', :as => :monthly_deal_days, :action => 'day_navigator'
    get 'accounts/:account_id/deals/:year/:month', as: :monthly_account_deals, action: :monthly
    # TODO: なぜか page.redirect_to redirect_options_proc.call(@deal) でrequirements があるとうまくいかない
    get 'deals/:year/:month', :as => :monthly_deals, :action => 'monthly' #, :requirements => YEAR_MONTH_REQUIREMENTS
  end

  # DealSuggestionsController
  resources :deal_suggestions, :path => 'deals/suggestions', :only => [:index]

  get '/home' => 'home#index', :as => :home

  resource :user

  # SettlementsController
  controller :settlements do
    scope path: 'accounts/:account_id' do
      get 'settlements/new/:year/:month', as: :new_account_settlement, action: :new
      put 'settlements/new/:year/:month', :action => :update_source
      post 'settlements/new/:year/:month/deals', as: :new_account_settlement_deals, :action => :select_all_deals_in_source
      delete'settlements/new/:year/:month/deals', :action => :remove_all_deals_in_source
      delete 'settlements/new/:year/:month', action: :destroy_source
      post 'settlements/:year/:month', as: :account_settlements, action: :create
      get  'settlements/:year/:month', action: :summary
    end
    resources :settlements, :only => [:show, :destroy] do
      member do
        get 'print_form'
        put 'submit'
      end
    end
    get 'settlements/:year/:month', as: :settlements, action: :summary
  end

  # AssetsController
  controller :assets do
    scope :path => 'f' do # /assets はじまりは無視されるため
      get 'assets/:year/:month', {:as => :monthly_assets, :action => :monthly}.merge(YEAR_MONTH_REQUIREMENTS)
      resources :assets, :only => [:index]
    end
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

  # ExportController
  controller :export do
    get 'export', :as => :export, :action => "index"
    get 'export/:filename.:format', :as => :export_file, :action => "whole"
  end

  # HelpController
  controller :help do
    get 'help/index'
    get 'help/functions'
    get 'help/faq'
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
