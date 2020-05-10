module EntrySpecHelper
  def new_general_entry(account_id, amount, options = {})
    account_id = account_id.kind_of?(Symbol) ? Fixtures.identify(account_id) : account_id
    user_id = Account::Base.find_by(id: account_id).try(:user_id)
    e = Entry::General.new(:amount => amount, :account_id => account_id)
    manual_attributes = {:date => Time.zone.today, :daily_seq => 1, :user_id => user_id}.merge(options)
    manual_attributes.keys.each do |key|
      e.send("#{key}=", manual_attributes[key])
    end
    e
  end
end