module Messages
  def self.included(base)
    base.helper_method :term, :message_on_create, :message_on_update, :message_on_destroy, :confirm_message_on_destroy
  end

  private
  
  def term(key, options = {})
    options[:scope] = ['terms', bookkeeping_style? ? :bookkeeping : :kozuchi]
    options[:default] = :"terms.#{key}"

    t(key, options)
  end

  def message_on_create(obj, additional_message = '')
    I18n.t("messages.complete.create", :target => human_name_of(obj)) + additional_message
  end

  def message_on_update(obj, additional_message = '')
    I18n.t("messages.complete.update", :target => human_name_of(obj)) + additional_message
  end

  def message_on_destroy(obj, additional_message = '')
    I18n.t("messages.complete.destroy", :target =>  human_name_of(obj)) + additional_message
  end

  def confirm_message_on_destroy(obj)
    I18n.t("messages.confirm.destroy", :target =>  human_name_of(obj))
  end

  def human_name_of(obj)
    obj.respond_to?(:human_name) ? obj.human_name : obj
  end

end

