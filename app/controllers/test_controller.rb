require 'sqlite3'
class TestController < ApplicationController
  def test
    @message = "Started."
    db = SQLite3::Database.new('db\kozuchi_development.db')
    db.execute('insert into account (name, type) values (\'test\', 1);')
    db.close
    @message = "Ended."
  end
end
