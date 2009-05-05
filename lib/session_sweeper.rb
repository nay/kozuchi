#!/usr/bin/env /usr/local/kozuchi/script/runner

class SessionSweeper
  def self.delete
    c = ActiveRecord::Base.connection
    r = c.execute "delete from sessions where DATE(updated_at) <= SUBDATE(CURRENT_DATE,INTERVAL 7 DAY);"
  end
end

SessionSweeper.delete
