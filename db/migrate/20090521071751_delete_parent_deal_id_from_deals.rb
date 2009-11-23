# SubordinateDeal 削除に伴うデータ整理
class DeleteParentDealIdFromDeals < ActiveRecord::Migration
  def self.up
    remove_column :deals, :parent_deal_id
    execute "update deals set type='Deal::General' where type='SubordinateDeal'"
  end

  # データは不可逆
  def self.down
    add_column :deals, :parent_deal_id, :integer
  end
end
