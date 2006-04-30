class Account < ActiveRecord::Base
  attr_accessor :account_type_name
  validates_uniqueness_of :name
  validates_presence_of :name, :account_type

  def self.get_account_type_name(account_type)
    account_type_names = {1 => "口座", 2 => "費目", 3 => "収入内訳"}
    account_type_names[account_type]
  end

  def account_type_name
    @account_type_name ||= Account.get_account_type_name(self.account_type)
  end
  
  def self.find_all(user_id, types)
    account_types = "";
    types.each do |type|
      if account_types != ""
        account_types += ","
      end
      account_types += type.to_s
    end
    conditions = "user_id = ? and account_type in (#{account_types})"
    Account.find(:all,
                 :conditions => [conditions, user_id],
                 :order => "sort_key")
  end
    
end
