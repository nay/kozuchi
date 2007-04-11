class Settings::IncomesController < Settings::AccountsController

  def index
    load_accounts(3)
  end

end
