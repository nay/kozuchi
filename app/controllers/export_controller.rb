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
  end

end
