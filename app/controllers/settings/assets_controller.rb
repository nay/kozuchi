class Settings::AssetsController < Settings::AccountsController
  layout 'main'
  
  public :index, :create, :delete, :update
  
  protected
  def account_type
    :asset
  end
  
  private
  def account_class(asset_name)
    clazz = Account::Asset.types.detect{|a| a.asset_name == asset_name}
    raise "Unknown account type #{asset_name} in #{Account::Asset.types}" unless clazz
    clazz
  end

end
