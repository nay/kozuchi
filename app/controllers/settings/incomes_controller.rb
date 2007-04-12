class Settings::IncomesController < Settings::AccountsController

  public :index, :create, :delete, :update

  protected
  def account_type
    :income
  end

end
