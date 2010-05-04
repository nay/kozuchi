class Account::Asset < Account::Base

  BASIC_KINDS = {
    :cache =>             {:name => '現金', :banking => true},
    :banking_facility =>  {:name => '金融機関口座', :banking => true},
    :credit_card =>       {:name => 'クレジットカード', :credit => true},
    :credit =>            {:name => '債権', :credit => true}
  }

  type_order 1
  type_name '口座'
  short_name '口座'
  connectable_type Account::Asset

  def capital_fund?
    asset_kind == "capital_fund"
  end

  def credit_card?
    asset_kind == "credit_card"
  end


  # TODO: Rails 2.2
  def self.human_name
    '口座'
  end

  # TODO: クラスベースがちょっと大変過ぎる＆別アプリケーション化にとって厳しいので揺り戻し
  def base_type
    :asset
  end
  def linkable_to?(target_base_type)
    target_base_type == :asset
  end
  

  def name_with_asset_type
    "#{self.name}(#{ASSET_KINDS[self.asset_kind.to_sym][:name]})"
  end

  # 期間内の不明金合計（ーなら支出）を得る。
  # 最初の残高記入に伴うamountは不明金扱いしない。
  def unknown_flow(start_date, end_date)
    balances.without_initial.date_from(start_date).before(end_date).sum(:amount)

#    entries.sum(:amount,
#      :joins => "inner join deals on account_entries.deal_id = deals.id",
#      :conditions => ["deals.type = 'Balance' and confirmed = ? and deals.date >= ? and deals.date < ? and account_entries.initial_balance = ?", true, start_date, end_date, false]) || 0
  end

  # ---------- 口座種別の静的属性を設定するためのメソッド群
#  def self.types
#    [Account::Cache, Account::BankingFacility, Account::CreditCard, Account::Credit, Account::CapitalFund]
#  end
  
#  def self.type_name(name = nil)
#    return Account::Asset.type_name if self != Account::Asset
#    super
#  end

  def self.short_name(short_name = nil)
    return Account::Asset.short_name if self != Account::Asset
    super
  end
  
  def self.connectable_type(clazz = nil)
    return Account::Asset.connectable_type if self != Account::Asset
    super
  end

  def self.asset_name(asset_name = nil)
    return @asset_name unless asset_name
    @asset_name = asset_name
  end
  
  # 口座種類名からクラスを得る。
  # asset_name:: 口座種類名
  def self.asset_name_to_class(asset_name)
    types.detect{|a| a.asset_name == asset_name}  
  end

  # ---------- 機能

  validate :validates_partner_account

  def self.create_accounts(user_id, asset_kind, names, sort_key_start = 1)
    sort_key = sort_key_start
    for name in names
      self.create(:user_id => user_id, :name => name, :asset_kind => asset_kind.to_s, :sort_key => sort_key)
      sort_key += 1
    end
  end


  def asset_name
    self.class.asset_name
  end

  private
  def serialized_attributes
    super.merge({:type => self.asset_kind})
  end

end

class Account::RuleAssociatedAccountException < Exception
  def initialize(account_name)
    super self.class.new_message(account_name)
  end
  def self.new_message(account_name)
    "「#{account_name}」は精算口座として使われているため削除できません。"
  end
end
