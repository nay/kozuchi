class Preferences < ActiveRecord::Base
  set_table_name "preferences"
  belongs_to :user
  
  validates_uniqueness_of :user_id
  
  def self.get(user_id)
    return find(:first, :conditions => ["user_id = ?", user_id]) || Preferences.new(:user_id => user_id)
  end
  
  protected
  # セーブ後、事業利用フラグがオフの場合は特殊な処置をする
  def after_save
    unless self.business_use?
      # 資本金タイプの口座はすべて債権タイプに変更する
      Account.update_all("asset_type = #{Account::ASSET_CREDIT}", "asset_type = #{Account::ASSET_CAPITAL_FUND}")
    end
  end
  
  
end