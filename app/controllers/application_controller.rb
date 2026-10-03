class ApplicationController < ActionController::Base
  if ENV['BASIC_AUTH_NAME'].present? &&  ENV['BASIC_AUTH_PASSWORD'].present?
    http_basic_authenticate_with name: ENV['BASIC_AUTH_NAME'], password: ENV['BASIC_AUTH_PASSWORD']
  end

  protect_from_forgery
  include Messages

  include AuthenticatedSystem
  before_action :login_required, :load_user, :set_ssl
  helper :all
  helper_method :original_user, :bookkeeping_style?, :account_selection_histories, :last_selected_credit, :current_vague_date, :current_year, :current_month, :dummy_year_and_month
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
    current_vague_date.year
  end

  def current_month
    current_vague_date.month
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
    obj.errors.each do |error|
      f[:errors] << error.message
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

  # 最後に表示した年月日（VagueDate）。年月を指定しない移動（メニューの「家計簿」など）で、どこへ戻るかに使う
  # 日があれば家計簿の日で絞った一覧に、なければ月の一覧に戻る。まだ何も表示していなければ今月
  def current_vague_date
    @current_vague_date ||= session[:current_vague_date] ? VagueDate.parse(session[:current_vague_date]) : VagueDate.new(Time.zone.today.year, Time.zone.today.month)
  end

  # value - VagueDate、Date、[年, 月]、[年, 月, 日] のどれか
  # 次に読むときは、書いたセッションの値から作り直す
  def current_vague_date=(value)
    session[:current_vague_date] = VagueDate.from(value).to_s
    @current_vague_date = nil
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
