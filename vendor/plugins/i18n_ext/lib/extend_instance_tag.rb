# Make the label_tag to use i18n.
module ActionView
  module Helpers

    class InstanceTag
      def to_label_tag_with_i18n_ext(text = nil, options = {})
        if text.blank?
          begin
            translated_text = object.class.human_attribute_name(@method_name.to_s)
            text = translated_text unless translated_text.blank?
          rescue
            # Do nothing
          end
        end
        to_label_tag_without_i18n_ext(text, options)
      end

      alias_method_chain :to_label_tag, :i18n_ext
    end
  end
end