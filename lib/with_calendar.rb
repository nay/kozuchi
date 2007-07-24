# カレンダーと連動するコントローラを拡張するためのモジュール
module WithCalendar

  # params[:year]:: 年
  # params[:month]:: 月
  def change_month
    self.target_date = {:year => params[:year], :month => params[:month]}
    redirect_to_index
  end
  
  private
  def redirect_to_index(options = {})
    options.merge!({:action => 'index', :year => target_date[:year], :month => target_date[:month]})
    p "redirect_to_index #{options}"
    redirect_to options
  end
  
  def redirect_unless_month
    if !params[:year] || !params[:month]
      redirect_to_index
      return false
    end
    # TODO: ここでセッションに記憶
  end
  
end