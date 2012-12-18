module Messages
  def self.included(base)
    base.helper_method :term, :message_on_create, :message_on_update, :message_on_destroy, :confirm_message_on_destroy
  end

  private
  
  def term(key, *args)
    I18n.t("terms.#{key}", *args)
  end

  def message_on_create(obj)
    I18n.t("messages.complete.create", :target => human_name_of(obj))
  end

  def message_on_update(obj)
    I18n.t("messages.complete.update", :target => human_name_of(obj))
  end

  def message_on_destroy(obj)
    I18n.t("messages.complete.destroy", :target =>  human_name_of(obj))
  end

  def confirm_message_on_destroy(obj)
    I18n.t("messages.confirm.destroy", :target =>  human_name_of(obj))
  end

  def human_name_of(obj)
    obj.respond_to?(:human_name) ? obj.human_name : obj
  end

end

