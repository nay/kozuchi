YEAR_MONTH_REQUIREMENTS = {:year => /[0-9]*|_YEAR_/, :month => /[1-9]|10|11|12|_MONTH_/}

Kozuchi::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.

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


    # カスタマイズ
    resource :preferences, :only => [:show, :update]

    # シングルログイン
    resources :single_logins, :only => [:index, :create, :destroy]
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
    # :sub_resources => {:entries => {:only => [:create]}}
    # postだけにしたいが構造上 put のフォームの中から呼ばれて面倒なので
    match 'deals/:id/entries', :action => 'create_entry', :as => :deal_entries, :via => [:post, :put]

    ['general', 'balance', 'complex'].each do |t|
      post "#{t}_deals", :action => "create_#{t}_deal", :as => :"#{t}_deals"
      get "#{t}_deals/new", :action => "new_#{t}_deal", :as => :"new_#{t}_deal"
    end

    # TODO: なぜか page.redirect_to redirect_options_proc.call(@deal) でrequirements があるとうまくいかない
    get 'deals/:year/:month', :as => :monthly_deals, :action => 'monthly' #, :requirements => YEAR_MONTH_REQUIREMENTS
  end

  # DealSuggestionsController
  resources :deal_suggestions, :path => 'deals/suggestions', :only => [:index]

  # DealPatternsController
  resources :deal_patterns, :path => 'deals/patterns', :only => [:create]

  resource :mobile_device, :controller => :mobiles do
    member do
      get 'confirm_destroy'
    end
  end

  match '/home' => 'home#index', :as => :home

  resource :user

  # SettlementsController
  controller :settlements do
    get 'settlements/new/target_deals', :as => :new_settlement_target_deals, :action => :target_deals
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
      match 'deals/:year/:month', :as => :monthly_account_deals, :action => 'monthly'# TODO: なぜかあるとうまくいかない, :requirements => YEAR_MONTH_REQUIREMENTS
      match 'balance', :as => :account_balance, :action => :balance
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
    match 'balance_sheet/:year/:month', {:as => :monthly_balance_sheet, :action => 'monthly'}.merge(YEAR_MONTH_REQUIREMENTS)
    match 'balance_sheet', :action => :index, :as => :balance_sheet
  end

  # ProfitAndLossController
  controller :profit_and_loss do
    get :profit_and_loss, :action => :show
    match 'profit_and_loss/:year/:month', {:as => :monthly_profit_and_loss, :action => 'monthly'}.merge(YEAR_MONTH_REQUIREMENTS)
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
    match 'export', :as => :export, :action => "index"
    match 'export/:filename.:format', :as => :export_file, :action => "whole"
  end

  # HelpController
  controller :help do
    match 'help/:action'
  end

#  # TODO: except sessions,
#  map.connect ':controller/:action/:id'

  root :to => "welcome#index"
#  match 'news' => "welcome#news"

  match '/signup' => 'users#new', :as => :signup, :via => :get
  match '/signup' => 'users#create', :as => :signup_post, :via => :post # TODO: must be unified to signup
  match '/login' => 'sessions#create', :as => :login_post, :via => :post # TODO: change to login
  match '/logout' => 'sessions#destroy', :as => :logout, :via => :delete
  match '/singe_login' => 'sessions#update', :as => :single_login, :via => :put
  match '/activate/:activation_code' => 'users#activate', :as => :activate

  # 互換性のため
  match '/user/home' => 'users#activate_login_engine', :as => :activate_login_engine

  match '/forgot_password' => 'users#forgot_password', :as => :forgot_password
  match  '/deliver_password_notification' => 'users#deliver_password_notification', :via => :post, :as => :deliver_password_notification
  match '/password/:password_token' => 'users#edit_password', :via => :get, :as => :password
  match '/password/:password_token' => 'users#update_password', :via => :post


  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
