class Preferences < ActiveRecord::Base
  set_table_name "preferences"
  belongs_to :user
  
#  validates_uniqueness_of :user_id
  
#  def self.get(user_id)
#    return find(:first, :conditions => ["user_id = ?", user_id]) || Preferences.new(:user_id => user_id)
#  end
  
  protected
  
  # セーブ後、事業利用フラグがオフの場合は特殊な処置をする
  def after_save
    unless self.business_use?
      # 資本金タイプの口座はすべて債権タイプに変更する
      Account::Base.update_all("asset_kind = 'credit'", "asset_kind = 'capital_fund'")
    end
  end
  
end