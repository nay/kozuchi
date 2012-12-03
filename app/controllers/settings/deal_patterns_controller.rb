# -*- encoding : utf-8 -*-
class Settings::DealPatternsController < ApplicationController
  layout 'main'
  menu_group "設定"
  menu "記入パターン"

  before_filter :find_deal_pattern, :only => [:show, :update, :destroy]
  before_filter :find_or_build_deal_pattern, :only => [:create_entry]

  def index
    @deal_patterns = current_user.deal_patterns.order('updated_at desc').all # TODO: paginate
  end
  
  def show
    @deal_pattern.fill_complex_entries
  end

  def new
    @deal_pattern = current_user.deal_patterns.build
    @deal_pattern.fill_complex_entries
  end

  def create
    @deal_pattern = current_user.deal_patterns.build(params[:deal_pattern])
    if @deal_pattern.save
      redirect_to settings_deal_patterns_path, :notice => message_on_create(@deal_pattern)
    else
      @deal_pattern.fill_complex_entries
      render :new
    end
  end

  def update
    @deal_pattern.attributes = params[:deal_pattern]
    if @deal_pattern.save
      redirect_to settings_deal_patterns_path, :notice => message_on_update(@deal_pattern)
    else
      render :show
    end
  end

  def destroy
    human_name = @deal_pattern.human_name # entryが削除されると再現できなくなる
    @deal_pattern.destroy
    redirect_to settings_deal_patterns_path, :notice => message_on_destroy(human_name)
  end

  # 記入欄を増やす
  def create_entry
    entries_size = params[:deal_pattern][:debtor_entries_attributes].size
    @deal_pattern.attributes = params[:deal_pattern]
    @deal_pattern.fill_complex_entries(entries_size+1)
    render @deal_pattern.new_record? ? :new : :show
  end

  # 指定されたコードでそのユーザーに記入パターンが登録済みか調べる
  def code
    if pattern_deal = current_user.deal_patterns.find_by_code(params[:code])
      render :text => pattern_deal.code
    else
      render :text => '' # :nothing => true だと半角スペースが入って返されてしまうので
    end
  end


  private

  def find_deal_pattern
    @deal_pattern = current_user.deal_patterns.find(params[:id])
  end
  def find_or_build_deal_pattern
    @deal_pattern = if params[:id] == 'new'
      current_user.deal_patterns.build
    else
      current_user.deal_patterns.find(params[:id])
    end
  end
end
