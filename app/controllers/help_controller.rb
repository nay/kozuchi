# とりあえず単純なヘルプ
class HelpController < ApplicationController
  skip_before_action :login_required
  menu_group "ヘルプ"
  menu "小槌の特徴", :only => [:index]
  menu "できること", :only => [:functions]
  menu "FAQ", :only => [:faq]
  
  # 特徴
  def index
  end
  
  # 各画面の役割
  def functions
  end
  
  # FAQ
  def faq
  end

end
