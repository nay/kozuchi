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
    if options[:updated_deal_id]
      updated_deal = BaseDeal.find(options[:updated_deal_id])
      year = updated_deal.year
      month = updated_deal.month
    else
      year = target_date[:year]
      month = target_date[:month]
    end
    options.merge!({:action => 'index', :year => year, :month => month})
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