class ExportController < ApplicationController
  layout 'main'
  menu_group "データ管理"
  menu "エクスポート"

  def index
    @export_file_name = "kozuchi-#{Date.today.to_s(:db)}"
  end

  def whole
    options = {:layout => false}
    options[:content_type] = "application/octet-stream" if params[:download] == "1"
    render options
#    respond_to do |format|
#      format.xml { render :layout => false}
#      format.csv {
#        lines = []
#        lines << current_user.assets.each{|a| a.to_csv}
#        lines << current_user.expenses.each{|a| a.to_csv}
#
#      }
#    end
  end

end
