class Settings::IncomesController < Settings::AccountsController

  public :create, :delete, :update

  def index
    load_accounts(3)
  end

end
