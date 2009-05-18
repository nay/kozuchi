# 勘定の登録・削除・変更処理の規定クラスとなるコントローラ。
class Settings::AccountsController < ApplicationController
  layout 'main'
  include TermHelper
  cache_sweeper :export_sweeper
  
end
