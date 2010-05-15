# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  mobile_filter
  trans_sid
  include AuthenticatedSystem
  before_filter :set_content_type_for_mobile
  before_filter :login_required, :load_user, :set_ssl
  helper :all
  helper_method :original_user
  attr_writer :menu_group, :menu
  protected :'menu_group=', :'menu='

  # Deal 編集系アクション群を宣言するメタメソッド

  # options - :render_options_proc, :redirect_options_proc
  def self.deal_actions_for(*args)
    options = args.extract_options!
    render_options_proc = options[:render_options_proc]
    redirect_options_proc = options[:redirect_options_proc]
    ajax = options[:ajax]
    raise "render_options_proc is required to do ajax" if ajax && (!render_options_proc || !redirect_options_proc)
    raise "redirect_options_proc is required" unless redirect_options_proc

    args.each do |deal_type|
      render_options = render_options_proc ? render_options_proc.call(deal_type) : {}
      # new_xxx
      case deal_type.to_s
      when /general/
        define_method "new_#{deal_type}" do
          @deal = current_user.general_deals.build
          @deal.build_simple_entries
          flash[:"#{controller_name}_deal_type"] = deal_type # reloadに強い
          render render_options unless render_options.blank?
        end
      when /complex/
        define_method "new_#{deal_type}" do
          @deal = current_user.general_deals.build
          load = params[:load] ? current_user.general_deals.find_by_id(params[:load]) : nil
          if load
            @deal.load(load)
            @deal.fill_complex_entries
          else
            @deal.build_complex_entries
          end
          flash[:"#{controller_name}_deal_type"] = deal_type # reloadに強い
          render render_options unless render_options.blank?
        end
      when /balance/
        define_method "new_#{deal_type}" do
          @deal = current_user.balance_deals.build
          flash[:"#{controller_name}_deal_type"] = deal_type # reloadに強い
          render render_options unless render_options.blank?
        end
      end

      # create_xxx
      define_method "create_#{deal_type}" do
        size = params[:deal] && params[:deal][:creditor_entries_attributes] ? params[:deal][:creditor_entries_attributes].size : nil
        @deal = current_user.send(deal_type.to_s =~ /general|complex/ ? 'general_deals' : 'balance_deals').new(params[:deal])

        if @deal.save
          flash[:notice] = "#{@deal.human_name} を追加しました。" # TODO: 他コントーラとDRYに
          flash[:"#{controller_name}_deal_type"] = deal_type
          p "going to call write_target_date. @deal.dete = #{@deal.date.inspect}"
          write_target_date(@deal.date)
#          flash[:day] = @deal.date.day
          if ajax
            render :update do |page|
              page.redirect_to redirect_options_proc.call(@deal)
            end
          else
            redirect_to redirect_options_proc.call(@deal)
          end
        else
          if deal_type.to_s =~ /complex/
            @deal.fill_complex_entries(size)
          end
          if ajax
            render :update do |page|
              page[:deal_forms].replace_html render_options
            end
          else
            if render_options.blank?
              render :action => "new_#{deal_type}"
            else
              render render_options
            end
          end
        end
      end
    end
  end




  # メニューグループを指定する
  def self.menu_group(menu_group, options = {})
    before_filter(options) {|controller| controller.send(:'menu_group=', menu_group) }
  end
  # メニューを指定する
  def self.menu(menu, options = {})
    before_filter(options) {|controller| controller.send(:'menu=', menu) }
  end

  protected

  def original_user
    @original_user ||= User.find_by_id(session[:original_user_id]) if session[:original_user_id]
    @original_user
  end

  def original_user=(user)
    session[:original_user_id] = user ? user.id : nil
    @original_user = user || false
  end

  
  private

  def find_date
    @date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
  end

  def find_account
    @account = current_user.accounts.find(params[:account_id])
  end

  def set_content_type_for_mobile
    headers["Content-Type"] = "text/html; chartset=Shift_JIS" if request.mobile?
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
      write_target_date Date.today
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
      today = Date.today
      session[:target_date][:day] = today.day if session[:target_date][:year].to_s == today.year.to_s && session[:target_date][:month].to_s == today.month.to_s
    end
  end
  
    
  #TODO: どこかにありそうなきがするが・・・
  def to_date(hash)
    raise "no hash" unless hash
    Date.new(hash[:year].to_i, hash[:month].to_i, hash[:day].to_i)
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

  def require_mobile
    raise UnexpectedUserAgentError unless request.mobile?
  end
end
