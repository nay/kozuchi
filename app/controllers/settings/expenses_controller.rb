class Settings::ExpensesController < Settings::AccountsController

  public :create, :delete, :update

  def index
    load_accounts(2)
  end

end
