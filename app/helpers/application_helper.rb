# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include LoginEngine
  include TermHelper

  def html_tag(&block)
    inner_content = capture(&block)
    content = <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
#{inner_content}
</html>
EOF
    concat content, block.binding
  end
  
  def head_tag(*stylesheets, &block)
    inner_content = capture(&block)
    content = <<EOF
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <meta http-equiv="Content-Script-Type" content="text/javascript; charset=utf-8" />
    <meta name="author" content="Nay" />
    <meta http-equiv="content-style-type" content="text/css" />
    #{stylesheet_link_tag *stylesheets.insert(0, 'common')}
    #{javascript_include_tag 'prototype'}
    #{render :partial => "shared/google_analytics"}
    #{inner_content}
  </head>
EOF
    concat content, block.binding
  end

  def body_tag(&block)
    inner_content = capture(&block)
    content = <<EOF
  <body>
    <div id="page">
#{inner_content}
#{render :partial => "shared/footer"}
    </div>
  </body>
EOF
    concat content, block.binding
  end

  # 通信欄
  def flash_notice
    if flash[:notice] || flash[:notice].to_s != ""
      return "<div id=\"notice\">#{h flash[:notice]}</div>"
    end
    ''
  end

  # 口座に注目したときの表記
  def display_account_entry(entry, style = nil)
    e = entry.another_account_entry
    <<EOS
      <td class="date" #{style}>#{format_date e.deal.date}</td>
      <td class="number" #{style}>#{e.deal.daily_seq}</td>
      <td class="summary" #{style}>#{h e.deal.summary}</td>
      <td class="account" #{style}>#{h e.account.name}</td>
      <td class="amount" #{style}>#{number_with_delimiter(e.amount) if e.amount >= 0}</td>
      <td class="amount" #{style}>#{number_with_delimiter(e.amount.abs) if e.amount < 0}</td>
EOS
  end
  def display_account_entry_header
    <<EOS
      <th class="date">年月日</th>
      <th> </th>
      <th class="summary">摘要</th>
      <th class="account"></th>
      <th class="amount">出金</th>
      <th>入金</th>
EOS
  end


  # optgroup を使わずに口座を選ばせるリストを表示する
  def select_account(object, method, account_type, with_asset_type = true, options = {}, html_options = {})
    accounts = @user.accounts.types_in(account_type)
    select(object, method, accounts.collect{|a| [with_asset_type ?  a.name_with_asset_type : a.name, a.id] }, options, html_options)
  end


  def account_options(user, account_type)
    options = ''
    accounts = user.accounts.types_in(account_type)
    unless accounts.empty?
      options += "<optgroup label='#{accounts.first.class.type_name}'>"
      for account in accounts
        options += "<option value='#{account.id}'>#{account.name}</option>"
      end
      options += "</optgroup>"
    end
    options
  end

  def format_year(year)
    "#{year}年"
  end
  def format_month(month)
    "#{month}月"
  end
  def format_day(day)
    "#{day}日"
  end
  
  WEEKDAY_SHORTNAMES = ['日', '月', '火', '水', '木', '金', '土']
  def format_wday(wday)
    "（#{WEEKDAY_SHORTNAMES[wday]}）"
  end
  
  def format_date_full(date)
    format_year(date.year) + format_month(date.month) + format_day(date.day) + format_wday(date.wday)
  end
   
  def header_menu(menu_title, url_options)
    if controller.title != menu_title
      link_to(menu_title, url_options)
    else
      '<span class="current">' + menu_title + '</span>'
    end
  end
  
  def format_date(date)
    date.strftime('%Y/%m/%d')
  end
  
  def format_datetime(date)
    date.strftime('%Y/%m/%d %H:%M')
  end
  
  def user_color_style
    # TODO: なんとかしたい
    begin
      user = User.find(session[:user_id])
    rescue
      user = nil
    end
    return '' unless user && user.preferences
    bgcolor = user.preferences.color
    return '' unless bgcolor;
    style_content = "background-color: #{bgcolor};"
    return 'style="'+h(style_content)+'"'
  end
  
  def format_deal(deal)
    return "記入 #{deal.date}-#{deal.daily_seq}"
  end
  
  # 帳簿系表示ヘルパー
  # 一行を表示する　(table.book の下で呼ばれることを前提とする)
  def book_line(contents = {})
    string = "<tr>\n"
    string += "<td>#{h contents[:name]}</td>\n" if contents[:name]
    string += "<td class='percentage'>#{contents[:percentage]}%</td>\n" if contents[:percentage]
    string += "<td class='amount'>#{number_with_delimiter(contents[:amount])}</td>\n" if contents[:amount]
    string += "</tr>\n"
    string
  end

  class AccountGroup
    attr_reader :name, :accounts

    # TODO: きれいにしたい
    def self.groups(accounts, is_asc)
      groups = []
      for account in accounts do
        if account.kind_of?(Account::Asset)
          assets = AccountGroup.new("口座") if !assets
          assets << account
        elsif account.kind_of?(Account::Expense)
          expenses = AccountGroup.new("費目") if !expenses
          expenses << account
        else
          incomes = AccountGroup.new("収入内訳") if !incomes
          incomes << account
        end
      end
      if (is_asc)
        groups << assets if assets
        groups << incomes if incomes
        groups << expenses if expenses
      else
        groups << expenses if expenses
        groups << assets if assets
        groups << incomes if incomes
      end
      return groups
    end
  
    def initialize(name)
      @name = name
      @accounts = []
    end
  
    def << (account)
      @accounts << account
    end
  end
  
  def load_menu(url)
    Menues.side_menues.load(url)
  end
  
  def header_menues
    Menues.header_menues
  end
  
  def header_menu
    content = "<div id=\"header_menu\">"
    for menu in Menues.header_menues
      if @menu_tree && menu.name != @menu_tree.name
        content += link_to(menu.name, menu.url_option)
      else
        content += "<span class=\"current\">#{menu.name}</span>"
      end
    end
    content += "</div>"
  end

  # メニュー設定
  # カスタマイズを許す可能性がある（少なくとも利用モードで表現が変わる）のでユーザー毎にオブジェクトを作れる感じに
  # メニュー自体はログインしていなくても利用することを忘れずに
  class Menues
    def self.header_menues
      t = MenuTree.new
      t.add_menu('ホーム', :controller => "/home", :action => 'index')
      t.add_menu('家計簿', :controller => "/deals", :action => 'index')
      t.add_menu('精算', :controller => '/settlements', :action => 'new')
      t.add_menu('基本設定', :controller => "/settings/assets", :action => "index")
      t.add_menu('高度な設定', :controller => "/settings/friends", :action => "index")
      t.add_menu('ヘルプ', :controller => "/help", :action => "index")
#      t.add_menu('ログアウト', logout_path)  # TODO
      t.add_menu('ログアウト', :controller => "/sessions", :action => "destroy")
      t
    end
    
    def self.side_menues
      menues = Menues.new

      menues.create_menu_tree('家計簿') {|t|
        t.add_menu('仕訳帳', :controller => '/deals', :action => 'index')
#        t.add_menu('日めくり', :controller => '/daily_booking', :action => 'index')
        t.add_menu('口座別出納', :controller => '/account_deals', :action => 'index')
        t.add_menu('収支表', :controller => '/profit_and_loss', :action => 'index')
        t.add_menu('資産表', :controller => '/assets', :action => 'index')
        t.add_menu('貸借対照表', :controller => '/balance_sheet', :action => 'index')
      }
      
      menues.create_menu_tree('精算') {|t|
        t.add_menu('新しい精算', :controller => '/settlements', :action => 'new')
        t.add_menu('一覧', :controller => '/settlements', :action => 'index')
        t.add_menu('詳細', :controller => '/settlements', :action => 'view')
      }
      
      menues.create_menu_tree('基本設定') {|t|
        t.add_menu('口座', :controller => '/settings/assets', :action => 'index')
        t.add_menu('費目', :controller => '/settings/expenses',:action => 'index')
        t.add_menu('収入内訳', :controller => '/settings/incomes',:action => 'index')
        t.add_menu('プロフィール', :controller => '/users',:action => 'edit')
      }
      
      menues.create_menu_tree('高度な設定') {|t|
        t.add_menu('フレンド', :controller => '/settings/friends',:action => 'index')
        t.add_menu('取引連動',:controller => '/settings/deal_links', :action => 'index')
        t.add_menu('受け皿', :controller => '/settings/partner_account', :action => 'index')
        t.add_menu('カスタマイズ', :controller => '/settings/preferences',:action => 'index')
        t.add_menu('精算ルール', :controller => '/settings/account_rules',:action => 'index')
      }
      
      menues.create_menu_tree('ヘルプ') {|t|
        t.add_menu('小槌の特徴', :controller => '/help', :action => 'index')
        t.add_menu('できること', :controller => '/help', :action => 'functions')
        t.add_menu('FAQ', :controller => '/help', :action => 'faq')
      }
      menues
    end
  
    def initialize
      @trees = []
    end
    
    # 現在のurlに対して出すべきメニューセットと現在のメニューを返す
    def load(url_option)
      @trees.each{|t| t.each {|menu| return t, menu if menu.url_option == url_option}}
      nil
    end
    
    def create_menu_tree(name)
      tree = MenuTree.new
      tree.name = name
      @trees << tree
      yield tree
    end
    
    class MenuTree
      attr_accessor :name
      def initialize
        @array = []
      end
      def add_menu(name, url_option)
        menu = Menu.new
        menu.name = name
        menu.url_option = url_option
        @array << menu
      end
      def each(&block)
        @array.each &block
      end
      def last
        @array.last
      end
    end
  
    class Menu
      attr_accessor :name, :url_option
    end
    
  end

end
