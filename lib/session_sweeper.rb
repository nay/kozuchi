#!/usr/bin/env /usr/local/kozuchi/script/runner

class SessionSweeper
  def self.delete
    c = ActiveRecord::Base.connection
    r = c.execute "delete from sessions where DATE(updated_at) <= NOW() - INTERVAL '1 week';"
  end
end

SessionSweeper.delete
