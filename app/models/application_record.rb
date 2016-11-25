class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include ActionView::Helpers::TextHelper # to use truncate in InstanceHuman
  include InstanceHuman

  def self.unsavable
    include Unsavable unless include?(Unsavable)
  end

end
