class Settings::AssetsController < Settings::AccountsController
  layout 'main'
  
  public :index, :create, :delete, :update
  
  protected
  def account_type
    :asset
  end

end
