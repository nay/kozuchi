class Settings::IncomesController < Settings::AccountsController

  public :index, :create, :delete, :update

  protected
  def account_type
    :income
  end

  private
  def account_class
    Account::Income
  end

end
