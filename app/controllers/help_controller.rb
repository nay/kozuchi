# とりあえず単純なヘルプ
class HelpController < ApplicationController
  layout 'main'
  
  before_filter :load_user
  
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
