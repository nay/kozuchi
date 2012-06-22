# -*- encoding : utf-8 -*-
class WelcomeController < ApplicationController
  skip_before_filter :login_required
    
  def index
    if !request.mobile? && (!defined?(DISPLAY_NEWS) || DISPLAY_NEWS)
      # 取得できたニュースは同じ日に限りキャッシュする。
      # ファイルが存在したまま再起動するとKozuchi.news_updated_onがnilになるのでそのときも expire でカバーする
      expire_fragment(:action_suffix => 'news') if !Kozuchi.news_updated_on || Kozuchi.news_updated_on < Date.today
      
      # キャッシュがなければニュースを取ってくる。エラー時はnilが入るのでテンプレート側でキャッシュするかどうかを制御する。
      @news = fragment_exist?(:action_suffix => 'news') ? true : News.get
    end
  end
    
end
