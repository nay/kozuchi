class Settings::ExpensesController < Settings::AccountsController

  public :index, :create, :delete, :update

  protected
  def account_type
    :expense
  end

  private
  def account_class(asset_name)
    Account::Expense
  end

end
