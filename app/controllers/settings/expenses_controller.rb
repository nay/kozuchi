class Settings::ExpensesController < Settings::AccountsController

  def index
    load_accounts(2)
  end

end
