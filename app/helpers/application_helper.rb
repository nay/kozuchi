# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include LoginEngine
  
  include TermHelper
  
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
  
  def user_color_style
    return '' unless session[:user] && session[:user].preferences
    bgcolor = session[:user].preferences.color
    return '' unless bgcolor;
    style_content = "background-color: #{bgcolor};"
    return 'style="'+style_content+'"'
  end
  
  def format_deal(deal)
    return "記入 #{deal.date}-#{deal.daily_seq}"
  end
  
  # 帳簿系表示ヘルパー
  # 一行を表示する　(table.book の下で呼ばれることを前提とする)
  def book_line(contents = {})
    string = "<tr>\n"
    string += "<td>#{contents[:name]}</td>\n" if contents[:name]
    string += "<td class='percentage'>#{contents[:percentage]}%</td>\n" if contents[:percentage]
    string += "<td class='amount'>#{number_with_delimiter(contents[:amount])}</td>\n" if contents[:amount]
    string += "</tr>\n"
    string
  end

  class AccountGroup
    attr_reader :name, :accounts

    def self.groups(accounts, is_asc)
      groups = []
      for account in accounts do
        case account.account_type
        when 1
          assets = AccountGroup.new("口座") if !assets
          assets << account
        when 2
          expenses = AccountGroup.new("費目") if !expenses
          expenses << account
        when 3
          incomes = AccountGroup.new("収入内訳") if !incomes
          incomes << account
        end
      end
      if (is_asc)
        groups << assets if assets
        groups << expenses if expenses
        groups << incomes if incomes
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

  # メニュー設定
  # カスタマイズを許す可能性がある（少なくとも利用モードで表現が変わる）のでユーザー毎にオブジェクトを作れる感じに
  # メニュー自体はログインしていなくても利用することを忘れずに
  class Menues
    def self.header_menues
      t = MenuTree.new
      t.add_menu('家計簿', :controller => "/deals", :action => 'index')
      t.add_menu('基本設定', :controller => "/settings/assets", :action => "index")
      t.add_menu('高度な設定', :controller => "/expert_config", :action => "index")
      t.add_menu('ヘルプ', :controller => "/help", :action => "index")
      t.add_menu('ログアウト', :controller => "/user", :action => "logout")
      t
    end
    
    def self.side_menues
      menues = Menues.new

      menues.create_menu_tree('家計簿') {|t|
        t.add_menu('仕訳帳', :controller => '/deals', :action => 'index')
        t.add_menu('口座別出納', :controller => '/account_deals', :action => 'index')
        t.add_menu('収支表', :controller => '/profit_and_loss', :action => 'index')
        t.add_menu('資産表', :controller => '/assets', :action => 'index')
        t.add_menu('貸借対照表', :controller => '/balance_sheet', :action => 'index')
      }
      
      menues.create_menu_tree('基本設定') {|t|
        t.add_menu('口座', :controller => '/settings/assets', :action => 'index')
        t.add_menu('費目', :controller => '/settings/expenses',:action => 'index')
        t.add_menu('収入内訳', :controller => '/settings/incomes',:action => 'index')
        t.add_menu('プロフィール', :controller => '/user',:action => 'edit')
      }
      
      menues.create_menu_tree('高度な設定') {|t|
        t.add_menu('精算ルール', :controller => '/expert_config',:action => 'account_rules')
        t.add_menu('フレンド', :controller => '/expert_config',:action => 'friends')
        t.add_menu('取引連動',:controller => '/deal_links', :action => 'index')
        t.add_menu('受け皿', :controller => '/partner_account', :action => 'index')
        t.add_menu('カスタマイズ', :controller => '/settings/preferences',:action => 'index')
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
