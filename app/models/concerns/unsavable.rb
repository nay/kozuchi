module Unsavable
  def self.included(base)
    base.instance_eval do
      define_method :unsavable do
        raise "#{self.class} is unsavable." if self.class == base
      end
      private :unsavable
    end

    base.before_save :unsavable
  end
end