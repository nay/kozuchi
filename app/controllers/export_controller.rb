class ExportController < ApplicationController
  layout 'main'
  before_filter {|controller| controller.menu_group = "データ管理"}

  def index
  end

end
