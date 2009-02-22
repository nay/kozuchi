class Jpmobile::Mobile::AbstractMobile
  def docomo?
    kind_of?(Jpmobile::Mobile::Docomo)
  end
end

module Jpmobile::Helpers
    def docomo_utn_button_to(*args)
      result = button_to(*args)
      result.sub(/>/, " utn>")
    end
end

#ActionView::Base.class_eval { include Jpmobile::Helpers::Extension }