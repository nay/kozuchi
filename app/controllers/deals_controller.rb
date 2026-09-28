class DealsController < ApplicationController

  include Deals::SummaryTruncation

  helper :html5jp_graphs

  cache_sweeper :export_sweeper, :only => [:destroy, :update, :confirm, :create_general_deal, :create_complex_deal, :create_balance_deal]
  
  menu_group "家計簿"
  menu "家計簿"
  title '記入する', only: [:new]
  before_action :check_account
  before_action :find_deal, :only => [:edit, :load_deal_pattern_into_edit, :update, :confirm, :destroy, :show]
  before_action :find_new_or_existing_deal, :only => [:create_entry]
  before_action :find_account_if_specified, only: [:index, :today, :monthly, :daily, :new_general_deal, :new_complex_deal, :new_balance_deal, :create_general_deal, :create_complex_deal, :create_balance_deal]
  before_action :prepare_month_list, only: [:monthly, :daily]
  # NOTE: create_xxx_deal では @account はアクションでは使わないが、例えば残高記入で記入エラーが合った際の render で new の時点と画面が変わる恐れがあるため、元画面にあれば ajax でも伝わってくるようにしておく

  # 単数記入タブエリアの表示 (Ajax)
  def new_general_deal
    @deal = current_user.general_deals.build
    @deal.build_simple_entries
    flash[:"#{controller_name}_deal_type"] = 'general_deal' # reloadに強い
    render partial: 'general_deal_form'
  end

  def new_complex_deal
    @with_amount = false if !params[:with_amount].nil? &&  params[:with_amount]!= 'true'
    @deal = current_user.general_deals.build
    load = params[:load].present? ? current_user.general_deals.find_by(id: params[:load]) : nil
    pattern = nil
    if !load
      if params[:pattern_code].present?
        pattern =  current_user.deal_patterns.find_by(code: params[:pattern_code])
        # コードが見つからないときはクライアント側で特別に処理するので目印を返す
        unless pattern
          render plain: 'Code not found'
          return
        end
      end
      pattern ||= params[:pattern_id].present? ? current_user.deal_patterns.find_by(id: params[:pattern_id]) : nil
      pattern.use if pattern
      load ||= pattern
    end
    if load
      @deal.load(load)
      # 見つかったパターンが単純明細の場合は単純明細処理に切り替える
      if pattern && !@deal.complex?
        flash[:"#{controller_name}_deal_type"] = 'general_deal' # reloadに強い
        render partial: 'general_deal_form'
        return
      end
      @deal.fill_complex_entries
    else
      @deal.build_complex_entries
    end
    flash[:"#{controller_name}_deal_type"] = 'complex_deal' # reloadに強い
    render partial: 'complex_deal_form'
  end

  def new_balance_deal
    @deal = current_user.balance_deals.build
    flash[:"#{controller_name}_deal_type"] = 'balance_deal' # reloadに強い
    render partial: 'balance_deal_form'
  end

  # TODO: アクションを一つにする
  %w(general_deal complex_deal balance_deal).each do |deal_type|

    # create_xxx
    define_method "create_#{deal_type}" do
      size = deal_params[:creditor_entries_attributes].kind_of?(Array) ? deal_params[:creditor_entries_attributes].size : deal_params[:creditor_entries_attributes].try(:to_h).try(:size)
      @deal = current_user.send(deal_type.to_s =~ /general|complex/ ? 'general_deals' : 'balance_deals').new(deal_params)
      if @deal.save
        flash[:notice] = "#{@deal.human_name} を追加しました。#{truncation_message(@deal)}"
        flash[:"#{controller_name}_deal_type"] = deal_type
        write_target_date(@deal.date)
        account_has_been_selected(*@deal.accounts)
        render json: {
            id: @deal.id,
            deal: @deal.as_json(root: false, include: :readonly_entries),
            year: @deal.date.year,
            month: @deal.date.month,
            day: @deal.date.day,
            redirect_to: @deal.balance? ? monthly_account_deals_path(account_id: @deal.account.id, year: @deal.date.year, month: @deal.date.month, anchor: 'monthly') : nil,
            error_view: false
        }
      else
        if deal_type.to_s =~ /complex/
          @deal.fill_complex_entries(size)
        end
        render json: {
            id: @deal.id,
            year: @deal.date&.year || deal_params[:year],
            month: @deal.date&.month || deal_params[:month],
            day: @deal.date&.day || deal_params[:day],
            error_view: render_to_string(partial: "#{deal_type}_form")
        }
      end
    end
  end


  # 日ナビゲーター部品を返す (Ajax)
  def day_navigator
    write_target_date(params[:year], params[:month])
    @year, @month, @day = read_target_date
    render partial: 'shared/day_navigator', locals: {data: data_for_day_navigator}
  end

  RECENT_DEALS_SIZE = 5

  # 変更フォームを表示するAjaxアクション
  # :pattern_id が指定されていたら（TODO: I/F未実装、候補選択でできる予定）それをロードするが、なければもとのまま
  def edit
    load = nil
    if params[:pattern_id].present?
      load = current_user.deal_patterns.find_by(id: params[:pattern_id])
    end
    @deal.load(load) if load
    @deal.fill_complex_entries if load || @deal.kind_of?(Deal::General) && (params[:complex] == 'true' || !@deal.simple? || !@deal.summary_unified?)
    render :partial => 'edit'
  end

  def load_deal_pattern_into_edit
    raise "no pattern_code" unless params[:pattern_code].present?
    load =  current_user.deal_patterns.find_by(code: params[:pattern_code])
    # コードが見つからないときはクライアント側で特別に処理するので目印を返す
    unless load
      render plain: 'Code not found'
      return
    end
    @deal.load(load)
    @deal.fill_complex_entries if @deal.kind_of?(Deal::General) && (params[:complex] == 'true' || !@deal.simple? || !@deal.summary_unified?)
    render :partial => 'edit_form'
  end

  # 記入欄を増やすアクション
  # @deal を作り直して書き直す
  def create_entry
    entries_size = deal_params[:debtor_entries_attributes].to_h.size
    @deal.attributes = deal_params
    @deal.fill_complex_entries(entries_size+1)
    if @deal.new_record?
      render partial: 'complex_deal_form'
    else
      render :partial => 'edit_form'
    end
  end

  def update
    @deal.attributes = deal_params
    @deal.confirmed = true
    entries_size = params[:deal][:debtor_entries_attributes].try(:size)

    deal_type = @deal.kind_of?(Deal::Balance) ? 'balance_deal' : 'general_deal'
    if @deal.save
      write_target_date(@deal.date)
      account_has_been_selected(*@deal.accounts)
      flash[:notice] = "#{@deal.human_name} を更新しました。#{truncation_message(@deal)}"
      flash[:"#{controller_name}_deal_type"] = deal_type
      flash[:day] = @deal.date.day
      render json: {
          id: @deal.id,
          deal: @deal.as_json(root: false, include: :readonly_entries),
          year: @deal.date.year,
          month: @deal.date.month,
          day: @deal.date.day,
          error_view: false
      }
    else
      unless @deal.simple?
        @deal.fill_complex_entries(entries_size)
      end
      render json: {
          id: @deal.id,
          year: @deal.date.year,
          month: @deal.date.month,
          day: @deal.date.day,
          error_view: render_to_string(partial: 'edit_form')
      }
      #render :update do |page|
      #  page[:deal_editor].replace_html :partial => 'edit'
      #end
    end
  end

  # 仕分け帳画面を初期表示するための処理
  # 最後に表示した年月の一覧に移る。最後に表示したのが日で絞った一覧なら、その日で絞った一覧に移る
  def index
    flash.keep
    year, month = read_target_date
    redirect_to helpers.deals_list_path(@account&.id, year, month, last_filter_day(year, month))
  end

  # 今日で絞った一覧に移る
  def today
    flash.keep
    today = Time.zone.today
    redirect_to helpers.deals_list_path(@account&.id, today.year, today.month, today.day)
  end

  # 月表示 (総合 & 口座別)
  def monthly
    write_target_date(@year, @month)
    @day = read_target_date.third
    session.delete(:deals_filter_date)

    find_bookings(@start_of_month, @start_of_month.end_of_month)
  end

  # 日で絞った表示 (総合 & 口座別)
  # 月にない日（9月31日など）は、その月の近い日に直して移る
  def daily
    date = @start_of_month.change(day: params[:day].to_i.clamp(1, @start_of_month.end_of_month.day))
    return redirect_to(helpers.deals_list_path(@account&.id, date.year, date.month, date.day)) if date.day != params[:day].to_i

    write_target_date(date)
    @day = @filter_day = date.day
    session[:deals_filter_date] = date.to_s # 年月を指定しない移動（シングルログインなど）で、日で絞った一覧に戻れるように覚える

    find_bookings(date, date)
    render :monthly
  end

  # 記入の削除
  # Ajaxでリクエストされる前提
  def destroy
    @deal.destroy
    write_target_date(@deal.date)
    render json: {
        deal: {id: @deal.id},
        success_message: "#{@deal.human_name} を削除しました。"
    }
  end

  # キーワードで検索したときに一覧を出す
  def search
    raise InvalidParameterError if params[:keyword].blank?
    @keywords = params[:keyword].split(' ')
    @deals = current_user.deals.time_ordering.including(@keywords).distinct # NOTE: Rails4.1.0 関連の直後だとuniqがスコープにならず発動してしまうので最後につける必要がある。なお、ここではこれがないと発火前のsizeが重複分を含んでしまう。countはDISTINCTが重なってSQLエラーになるので view でlength を使っている
    @as_action = :index
  end

  
  # 確認
  # Ajaxでリクエストされる前提
  def confirm
    @deal.confirm!
    write_target_date(@deal.date)
    render json: {
      deal: {id: @deal.id},
      success_message:  "#{@deal.human_name} を確認しました。"
    }
  end

  private

  # 一覧（月表示・日で絞った表示）で、表示する月に関わるものを用意する
  # 明細の行のほかは、日で絞っていても月単位で出す
  def prepare_month_list
    @year = params[:year].to_i
    @month = params[:month].to_i
    @start_of_month = Date.new(@year, @month, 1)

    # フォーム用
    # NOTE: 残高変更後は残高タブを表示しようとするので、正しいクラスのインスタンスがないとエラーになる
    case flash[:"#{controller_name}_deal_type"]
    when 'balance_deal'
      @deal = Deal::Balance.new
      # TODO: 口座
    else
      @deal = Deal::General.new
      @deal.build_simple_entries
    end

    # 最近登録/更新された記入を常に5件まで表示する
    @recently_updated_deals = current_user.deals.recently_updated_ordered.includes(:readonly_entries).limit(RECENT_DEALS_SIZE)

    # 日ナビゲーターで記入のある日に印を付けるため、日で絞っていても月全体の記入の日を用意する
    @day_navigator_data = (@account ? @account.entries : current_user.deals).where(date: @start_of_month.all_month).select(:date).distinct

    # 上部精算概況
    if @account && @account.any_credit?
      @settlement_summaries = SettlementSummaries.new(current_user, past: 0, future: 2, target_account: @account, target_date: @start_of_month)
    end

    # 上部折れ線グラフ
    expenses, expenses_dates, label = @user.recent_from(@start_of_month, 4) do |user, d|
      if @account&.asset?
        @account.balance_before_date(d.end_of_month + 1)
      elsif @account&.expense?
        @account.total_flow(d.beginning_of_month, d.end_of_month)
      elsif @account&.income?
        @account.total_flow(d.beginning_of_month, d.end_of_month) * -1
      else
        user.expenses_summary(d.year, d.month)
      end
    end
    last_expenses, last_expenses_dates, label = @user.recent_from(@start_of_month << 12, 4) do |user, d|
      if @account&.asset?
        @account.balance_before_date(d.end_of_month + 1)
      elsif @account&.expense?
        @account.total_flow(d.beginning_of_month, d.end_of_month)
      elsif @account&.income?
        @account.total_flow(d.beginning_of_month, d.end_of_month) * -1
      else
        user.expenses_summary(d.year, d.month)
      end
    end
    label = if @account&.asset?
      "残高"
    elsif @account&.expense?
      "支出"
    elsif @account&.income?
      "収入"
    else
      "支出"
    end
    @expenses_summary = LineGraph.new([expenses], [label], y_label: "", max_grid: 3)
    @months_for_expenses = [""].concat(expenses_dates.map{|d| "#{d.month}月"})
  end

  # 一覧に出す明細の行を、from から to までの記入で用意する
  def find_bookings(from, to)
    if @account
      @account_entries = AccountEntries.new(@account, from, to)
    else
      @deals = current_user.deals.in_a_time_between(from, to).includes(:readonly_entries).order(:date, :daily_seq)
    end
  end

  # 最後に表示したのが year, month の月の日で絞った一覧なら、その日を返す
  def last_filter_day(year, month)
    date = Date.parse(session[:deals_filter_date]) if session[:deals_filter_date]
    date.day if date && date.year == year.to_i && date.month == month.to_i
  end

  def data_for_day_navigator
    current_user.deals.in_month(@year, @month).order(:date, :daily_seq).select(:date).distinct
  end

  def find_deal
    @deal = current_user.deals.find(params[:id])
  end

  def find_new_or_existing_deal
    if params[:id] == 'new'
      @deal = Deal::General.new
    else
      find_deal
    end
  end

  def find_account_if_specified
    @account = params[:account_id].present? ? current_user.accounts.find(params[:account_id]) : nil
    account_has_been_selected(@account) if @account
  end

end
