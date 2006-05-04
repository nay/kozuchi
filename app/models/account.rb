class Account < ActiveRecord::Base
  belongs_to :rule
  attr_accessor :account_type_name, :balance, :percentage
  validates_presence_of :name, :account_type
  
  @@asset_types = {1 => '現金', 2 => '金融機関口座', 3 => 'クレジットカード', 4 => '債権'}

  def self.asset_types
    @@asset_types
  end

  def self.get_account_type_name(account_type)
    account_type_names = {1 => "口座", 2 => "費目", 3 => "収入内訳"}
    account_type_names[account_type]
  end

  def account_type_name
    @account_type_name ||= Account.get_account_type_name(self.account_type)
  end
  
  def self.find_all(user_id, types, asset_types = nil)
    account_types = "";
    types.each do |type|
      if account_types != ""
        account_types += ","
      end
      account_types += type.to_s
    end
    conditions = "user_id = ? and account_type in (#{account_types})"
    if asset_types
      condition = "";
      asset_types.each do |t|
        if condition != ""
          condition += ","
        end
        condition += t.to_s
      end
      conditions += " and asset_type in (#{condition})"
    end
    Account.find(:all,
                 :conditions => [conditions, user_id],
                 :order => "sort_key")
  end

  # 口座別計算メソッド
  
  # 指定された日付より前の時点での残高を計算して balance に格納する
  def balance_before(date)
    @balance = AccountEntry.balance_at_the_start_of(self.user_id, self.id, date)
  end
    
end
