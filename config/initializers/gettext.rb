module ActionView
  class Base
    delegate :file_exists?, :to => :finder unless respond_to?(:file_exists?)
  end
end
