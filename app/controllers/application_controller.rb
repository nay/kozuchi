class ApplicationController < ActionController::Base
  if ENV['BASIC_AUTH_NAME'].present? &&  ENV['BASIC_AUTH_PASSWORD'].present?
    http_basic_authenticate_with name: ENV['BASIC_AUTH_NAME'], password: ENV['BASIC_AUTH_PASSWORD']
  end

  protect_from_forgery
  include Messages

  include AuthenticatedSystem
  before_action :login_required, :load_user, :set_ssl
  helper :all
  helper_method :original_user, :bookkeeping_style?, :account_selection_histories, :last_selected_credit, :current_year, :current_month, :dummy_year_and_month
  helper_method :settlement_source_exists?
  attr_writer :menu_group, :menu, :title
  helper_method :'menu_group=', :'menu=', :'title='


  # メニューグループを指定する
  def self.menu_group(menu_group, options = {})
    before_action(options) {|controller| controller.send(:'menu_group=', menu_group) }
  end
  # メニューを指定する
  def self.menu(menu, options = {})
    before_action(options) {|controller| controller.send(:'menu=', menu) }
  end

  def self.title(title, options = {})
    before_action(options) {|controller| controller.send(:'title=', title)}
  end

  protected

  def original_user
    @original_user ||= User.find_by(id: session[:original_user_id]) if session[:original_user_id]
    @original_user
  end

  def original_user=(user)
    session[:original_user_id] = user ? user.id : nil
    @original_user = user || false
  end


  private

  def settelemnt_sources
    session[:settlement_sources] ||= {}
  end

  def settlement_source_exists?(account, year, month)
    account_settlement_sources(account)[year.to_s + month.to_s].present?
  end

  def settlement_source(account, year, month)
    source = account_settlement_sources(account)[year.to_s + month.to_s]
    if source
      source.refresh(account)
    else
      source = SettlementSource.prepare(account: account, year: year, month: month)
      # 敢えてセッションには入れない。prepareしたてのもの = 初期化状態としたいので、何か手が加わるまで保存しない。
    end
    source
  end

  def account_settlement_sources(account)
    settelemnt_sources[account.id] ||= {}
  end

  def dummy_year_and_month
    {year: "_YEAR_", month: "_MONTH_"}
  end

  def current_year
    read_target_date.first
  end

  def current_month
    read_target_date.second
  end

  # TODO: deal系の機能とともにconcernsにでも出したい
  def deal_params
    # TODO: 直下のaccount_id, balance は残高専用だがいったんmixして定義する
    params.require(:deal).permit(:year, :month, :day, :summary, :summary_mode, :account_id, :balance, debtor_entries_attributes: [:amount, :reversed_amount, :account_id, :summary, :line_number], creditor_entries_attributes: [:amount, :reversed_amount, :account_id, :summary, :line_number])
  end

  ACCOUNT_SELECTION_HISTORY_MAX = 3 # TODO: 設定で変えられてもよい

  # 勘定がユーザーに意図的に選択されたことを記憶する
  # 新しいものほど前にくる
  def account_has_been_selected(*accounts)
    accounts.reverse_each do |account|
      raise "Not an account! #{account.inspect}" unless account.kind_of?(Account::Base)
      account_selection_histories.delete(account)
      account_selection_histories.unshift(account)
      account_selection_histories.pop while account_selection_histories.size > ACCOUNT_SELECTION_HISTORY_MAX
      session[:account_selection_histories] = account_selection_histories.map(&:id).join(",") # 一応オブジェクトを避けておく
    end
  end

  def account_selection_histories
    unless @account_selection_histories
      ids_in_session = (session[:account_selection_histories] || "").split(",").map(&:to_i)
      @account_selection_histories = if ids_in_session.empty?
        []
      else
        # ないものがあっても許す
        Account::Base.where("accounts.id in (?)", ids_in_session).sort{|a1, a2| ids_in_session.index(a1.id) <=> ids_in_session.index(a2.id)}
      end
    end
    @account_selection_histories
  end

  def last_selected_credit
    @last_selected_credit ||= account_selection_histories.detect{|a| a.kind_of?(Account::Asset) && a.any_credit? }
  end

  def clear_user_session
    [:account_id, :account_selection_histories].each{|key| session.delete(key)}
  end

  def find_date
    @date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
  end

  def find_account
    @account = current_user.accounts.find(params[:account_id])
  end

  def IE6?
    request.user_agent =~ /MSIE 6.0/ && !(request.user_agent =~ /Opera/)
  end

  # 開発環境でエラーハンドリングを有効にしたい場合にコメントをはずす
#  def local_request?
#    false
#  end

  def set_ssl
    if (defined? KOZUCHI_SSL) && KOZUCHI_SSL
      request.env["HTTPS"] = "on"
    end
  end

  def flash_validation_errors(obj, now = false)
    f = now ? flash.now : flash

    f[:errors] ||= []
    obj.errors.each do |attr, msg|
      f[:errors] << msg
    end
  end

  def flash_error(message, now = false)
    # TODO: validation error で Validation Failed が出るのを防ぐ
    begin
      message = message.gsub(/Validation failed: /, '')
    rescue
    end

    f = now ? flash.now : flash
    f[:errors] ||= []
    f[:errors] << message
  end

  def flash_notice(message, now = false)
    f = now ? flash.now : flash
    f[:notice] = message
  end

  # セッションに入っているyear, month, dayを配列で返す
  def read_target_date
    write_target_date unless session[:target_date]
    [session[:target_date][:year], session[:target_date][:month], session[:target_date][:day]]
  end

  # セッションに入っているyear, month, dayを更新する
  # 引数なし - 今日
  # date - 指定日
  # year, month, day - 指定どおり。month, day はなくてもいい
  def write_target_date(*args)
    session[:target_date] ||= {}
    if args.empty?
      write_target_date Time.zone.today
    elsif args.first.kind_of?(Date)
      session[:target_date][:year] = args.first.year
      session[:target_date][:month] = args.first.month
      session[:target_date][:day] = args.first.day
    else
      old_year = session[:target_date][:year]
      old_month = session[:target_date][:month]
      session[:target_date][:year] = args.first
      session[:target_date][:month] = args[1]
      # 同じ月で、日付が指定されていなければ、日付を変更しない
      session[:target_date][:day] = args[2] if (args[2] || old_year.to_i != session[:target_date][:year].to_i || old_month.to_i != session[:target_date][:month].to_i)
    end
    # day がないときは補完できるならする
    unless session[:target_date][:day]
      today = Time.zone.today
      session[:target_date][:day] = today.day if session[:target_date][:year].to_s == today.year.to_s && session[:target_date][:month].to_s == today.month.to_s
    end
  end


  #TODO: どこかにありそうなきがするが・・・
  def to_date(hash)
    raise "no hash" unless hash
    begin
      Date.new(hash[:year].to_i, hash[:month].to_i, hash[:day].to_i)
    rescue
      raise InvalidDateError, "「#{hash[:year]}/#{hash[:month]}/#{hash[:day]}」は不正な日付です。"
    end
  end

  # ユーザーオブジェクトを@userに取得する。なければnilが入る。
  def load_user
    @user = self.current_user
  end

  # 資産口座が1つ以上あり、全部で２つ以上の口座がないとダメ
  def check_account
    raise "no user" unless current_user
    if current_user.assets.size < 1 || current_user.accounts.size < 2
      render("book/need_accounts")
      return false
    end
    true
  end

  def bookkeeping_style?
    return false unless current_user
    current_user.preferences.bookkeeping_style?
  end

end
