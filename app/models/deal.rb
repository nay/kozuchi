# 異動明細クラス。
class Deal < BaseDeal
  attr_accessor :minus_account_id, :plus_account_id, :amount

  def before_create
    create_entries
  end
  
  def before_update
    account_entries.clear
    create_entries
  end

  # Prepare sugar methods
  def after_find
    raise "Invalid Deal Object with #{account_entries.size} entries." unless account_entries.size == 2
    
    @minus_account_id = account_entries[0].account_id
    @plus_account_id = account_entries[1].account_id
    @amount = account_entries[1].amount
  end
  
  private
  
  def create_entries
    account_entries.create(:user_id => user_id, :account_id => @minus_account_id, :amount => @amount.to_i*(-1))
    account_entries.create(:user_id => user_id, :account_id => @plus_account_id, :amount => @amount.to_i)
  end
end
