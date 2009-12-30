module ActionView::Helpers::ActiveRecordHelper
 def error_messages_for_with_i18n_ext(*params)
   # This extension adds :object_name option when :object_name is not specified,
   # so that the next 2 problems in the default rails (confirmed in 2.3.3, 2.3.4) will be fixed.
   # * The default method uses the first parameter as the key for i18n, but it's not always right.
   #   Instead, the object's class information should be used.
   # * The i18n key for the model name which has more than 2 words, such as 'SomeModel' is not same as model.class.human_name's key.
   #   That means you have to specify 2 keys, both 'some_model' and 'some model'.
   #   Instead, this extension make the method use 'some_model' pattern (same as human_name rule).
   # NOTE: With this extension, there are still 1 problem that if you have '_' in your translation it will be replaced to ' '.
   # To fix this, more changes will be needed.
   options = params.extract_options!.symbolize_keys
   unless options[:object_name]
     first_name = params.first
     first_object = options[:object] || instance_variable_get("@#{first_name}")
     options[:object_name] = first_object.class.human_name if first_object
   end
   params << options
   error_messages_for_without_i18n_ext(*params)
 end

 alias_method_chain :error_messages_for, :i18n_ext
end
