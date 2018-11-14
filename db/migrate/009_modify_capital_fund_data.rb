# -*- encoding : utf-8 -*-

class ModifyCapitalFundData < ActiveRecord::Migration[5.0]
  def self.up
    execute("update accounts set type = 'CapitalFund' where type = 'CaptitalFund';")
  end

  def self.down
    execute("update accounts set type = 'CaptitalFund' where type = 'CapitalFund';")
  end
end
