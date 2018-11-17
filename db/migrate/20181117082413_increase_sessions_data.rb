class IncreaseSessionsData < ActiveRecord::Migration[5.2]
  def up
    change_column :sessions, :data, :text, limit: 16777215
  end
  def down
    execute "DELETE from sessions" # 壊れる場合がありそうなので消しておく
    change_column :sessions, :data, :text, limit: 65535
  end
end
