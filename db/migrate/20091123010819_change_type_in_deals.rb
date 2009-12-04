class ChangeTypeInDeals < ActiveRecord::Migration
  def self.up
    execute "update deals set type = 'General' where type = 'Deal'"
  end

  def self.down
    execute "update deals set type = 'Deal' where type = 'General'"
  end
end
