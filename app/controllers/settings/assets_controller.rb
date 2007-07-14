class Settings::AssetsController < Settings::AccountsController
  layout 'main'
  
  public :index, :create, :delete, :update
  
  protected
  def account_type
    :asset
  end
  
  private
  def account_class
    clazz = Account::Asset.types.detect{|a| a.asset_name == params[:account][:type]}
    raise "Unknown account type #{params[:account][:type]} in #{Account::Asset.types}" unless clazz
    clazz
  end

end
