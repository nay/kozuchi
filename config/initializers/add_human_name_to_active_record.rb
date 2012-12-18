# -*- encoding : utf-8 -*-
module InstanceHuman
  def human_name
    "#{self.class.model_name.human}「#{truncate(name_for_human, :length => 20)}」"
  end

  def name_for_human
    name
  end
end
ActiveRecord::Base.send(:include, ActionView::Helpers::TextHelper) # to use truncate

ActiveRecord::Base.send(:include, InstanceHuman)
