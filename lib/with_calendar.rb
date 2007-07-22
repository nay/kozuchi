# カレンダーと連動するコントローラを拡張するためのモジュール
module WithCalendar

  # params[:year]:: 年
  # params[:month]:: 月
  def change_month
    self.target_date = {:year => params[:year], :month => params[:month]}
    redirect_to_index
  end
  
  private
  def redirect_to_index
    redirect_to :action => 'index', :year => target_date[:year], :month => target_date[:month]
  end
  
  def redirect_unless_month
    if !params[:year] || !params[:month]
      redirect_to_index
      return false
    end
    # TODO: ここでセッションに記憶
  end
  
end