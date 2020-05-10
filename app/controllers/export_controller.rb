class ExportController < ApplicationController
  menu_group "データ管理"
  menu "エクスポート"
  after_action :cache_export, :only => [:whole]

  def index
    @export_file_name = "kozuchi-#{Time.zone.today.to_s(:db)}"
  end

  def whole
    options = {:layout => false}
    options[:content_type] = "application/octet-stream" if params[:download] == "1"
    if fragment_exist? fragment_key
      options[:content_type] ||= "text/xml" if params[:format] == 'xml'
      render options.merge(:text => read_fragment(fragment_key))
    else
      render options
    end
  end

  private
  def fragment_key
    ExportSweeper.key(params[:format], current_user.id, request.host_with_port)
  end
  def cache_export
    return unless params[:format]
    write_fragment(fragment_key, response.body) unless fragment_exist?(fragment_key)
  end

end
