# -*- encoding : utf-8 -*-
class Settings::DealPatternsController < ApplicationController
  layout 'main'
  menu_group "設定"
  menu "記入パターン"

  before_filter :find_deal_pattern, :only => [:show, :update, :destroy]

  def index
    @deal_patterns = current_user.deal_patterns.order('updated_at desc').all # TODO: paginate
  end
  
  def show
    @deal_pattern.fill_complex_entries
  end

  def new
  end

  def create
  end

  def update
    @deal_pattern.attributes = params[:deal_pattern]
    if @deal_pattern.save
      redirect_to settings_deal_patterns_path, :notice => "#{@deal_pattern.human_name}を更新しました。"
    else
      render :show
    end
  end

  def destroy
  end

  private

  def find_deal_pattern
    @deal_pattern = current_user.deal_patterns.find(params[:id])
  end
end
