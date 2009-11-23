class ActiveRecord::Base
  def self.unsavable
    include Unsavable unless include?(Unsavable)
  end
end