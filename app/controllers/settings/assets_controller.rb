class Settings::AssetsController < Settings::AccountsController
  layout 'main'
  
  def index
    #資産口座の一覧をロードする    
    load_accounts(1)
  end

end
