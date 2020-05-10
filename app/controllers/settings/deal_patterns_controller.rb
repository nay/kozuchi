class Settings::DealPatternsController < ApplicationController

  include Deals::SummaryTruncation

  menu_group "設定"
  menu "記入パターン"
  menu "記入パターンの新規登録", only: [:new, :create]
  menu "記入パターンの編集", only: [:show, :update]

  before_action :find_deal_pattern, :only => [:show, :update, :destroy]
  before_action :find_or_build_deal_pattern, :only => [:create_entry]

  def index
    @deal_patterns = current_user.deal_patterns.order('updated_at desc') # TODO: paginate
  end
  
  # :pattern_code が指定されていたら対応する内容を画面上にコピーする
  # 何も指定していない場合、リセットの役割を果たす(TODO: I/F未実装)
  # request が Ajax かどうかで両対応
  def show
    load = nil
    if params[:pattern_code].present?
      load = current_user.deal_patterns.find_by(code: params[:pattern_code])
      unless load
        render :text => 'Code not found'
        return
      end
    elsif params[:pattern_id].present?
      load = current_user.deal_patterns.find_by(id: params[:pattern_id])
    end
    @deal_pattern.load(load) if load
    @deal_pattern.fill_complex_entries

    render action: :form, layout: !request.xhr?
  end

  # :pattern_code が指定されていたら対応する内容を画面上にコピーする
  # 何も指定していない場合、リセットの役割を果たす(TODO: I/F未実装)
  # request が Ajax かどうかで両対応
  def new
    load = nil
    if params[:pattern_code].present?
      load = current_user.deal_patterns.find_by(code: params[:pattern_code])
      unless load
        render :text => 'Code not found'
        return
      end
    elsif params[:pattern_id].present?
      load = current_user.deal_patterns.find_by(id: params[:pattern_id])
    end
    @deal_pattern = current_user.deal_patterns.build
    @deal_pattern.load(load) if load
    @deal_pattern.fill_complex_entries

    render action: :form, layout: !request.xhr?
  end

  def create
    @deal_pattern = current_user.deal_patterns.build(deal_pattern_params)
    if @deal_pattern.save
      redirect_to settings_deal_patterns_path, :notice => message_on_create(@deal_pattern, truncation_message(@deal_pattern))
    else
      @deal_pattern.fill_complex_entries
      render :new
    end
  end

  def update
    @deal_pattern.attributes = deal_pattern_params
    if @deal_pattern.save
      redirect_to settings_deal_patterns_path, :notice => message_on_update(@deal_pattern, truncation_message(@deal_pattern))
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
    entries_size = deal_pattern_params[:debtor_entries_attributes].kind_of?(Array) ? deal_pattern_params[:debtor_entries_attributes].size : deal_pattern_params[:debtor_entries_attributes].to_h.size
    @deal_pattern.attributes = deal_pattern_params
    @deal_pattern.fill_complex_entries(entries_size+1)
    render action: 'form', layout: false
  end

  # 指定されたコードでそのユーザーに記入パターンが登録済みか調べる
  def code
    scope = current_user.deal_patterns
    scope = scope.where(["deal_patterns.id != ?", params[:except]]) if params[:except].present?
    if pattern_deal = scope.find_by(code: params[:code])
      render :plain => pattern_deal.code
    else
      render :plain => '' # :nothing => true だと半角スペースが入って返されてしまうので
    end
  end


  private

  def deal_pattern_params
    # TODO: deal_params と似通っている
    params.require(:deal_pattern).permit(:code, :overwrites_code, :name, :summary, :summary_mode, debtor_entries_attributes: [:amount, :reversed_amount, :account_id, :summary, :line_number], creditor_entries_attributes: [:amount, :reversed_amount, :account_id, :summary, :line_number])
  end

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
