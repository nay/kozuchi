# -*- encoding : utf-8 -*-
class Settings::DealPatternsController < ApplicationController
  layout 'main'
  menu_group "設定"
  menu "記入パターン"

  before_filter :find_deal_pattern, :only => [:show, :update, :destroy]

  def index
    @deal_patterns = current_user.deal_patterns.all # TODO: paginate
  end
  
  def show
  end

  def new
  end

  def create
  end

  def update
  end

  def destroy
  end

  private

  def find_deal_pattern
    @deal_pattern = current_user.deal_patterns.find(params[:id])
  end
end
