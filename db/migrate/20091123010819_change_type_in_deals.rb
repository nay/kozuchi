# -*- encoding : utf-8 -*-

class ChangeTypeInDeals < ActiveRecord::Migration[5.0]
  def self.up
    execute "update deals set type = 'General' where type = 'Deal'"
  end

  def self.down
    execute "update deals set type = 'Deal' where type = 'General'"
  end
end
