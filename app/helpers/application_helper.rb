module ApplicationHelper

  include LoginEngine

  def date_selector_options
    (1..31).map{|day| [day, day]}
  end

  def setting_account_path(account)
    send("settings_#{account.class.to_sym.to_s}_path", id: account.id)
  end

  def active_class_if(condition, classes = [])
    classes << 'active' if condition
    classes
  end


  # 現在の機能によってシングルログインでアカウント移動時の移動先識別子を返す
  def single_login_destination
    if controller_name == 'deals' && action_name == 'monthly'
      :deals
    else
      nil
    end
  end

  def day_anchor(date)
    tag :span, :id => "day#{date.day}"
  end

  # deals などで副項目を扱う
  def display_account_name(account)
    names = h(account.name).split
    name = names.shift

    after_sub = ''
    while sub = names.pop
      after_sub = "<div class='sub_account_name'>#{sub}#{after_sub}</div>"
    end
    name << "<div class='sub_account_names'>#{after_sub}</div>".html_safe
    name.html_safe
  end

  # 上部メニューで使う
  def link_to_menu_group(menu_group, path, options = {})
    if menu_group != @menu_group
      link_to menu_group, path, options
    else
      content_tag("span", menu_group, :class => "current")
    end
  end

  # サイドメニューで使う
  def link_to_menu(menu, path)
    content_tag "div", :class => "side_menu#{'_current' if menu == @menu}" do
      if menu == @menu
        content_tag "span", menu
      else
        link_to menu, path
      end
    end
  end

  # 国際化にあわせたリファクタリングするまでの臨時措置。一行でエラーを表示する。attrを無視する。
  def error_message(obj)
    message = ""
    obj.errors.each do |attr, msg|
      message << msg
    end
    message
  end

  # 国際化に合わせるまでの臨時措置。attrを無視した従来の検証エラーに対応した表示ヘルパー。
  # flash_validation_errorからこちらにまず移行するために用意。
  def error_messages(obj)
    return "" if obj.errors.empty?
    messages = '<div id="errors" class="middle_box">'
    if obj.errors.size > 1
      messages << "<div>エラーがありました。ご確認ください。</div>\n"
      messages << "<ul>\n"
      obj.errors.each do |attr, msg|
        messages << "<li>#{msg}</li>"
      end
      messages << "</ul>"
    else
      # TODO: とりあえずなので適当な書き方
      obj.errors.each do |attr, msg|
        messages << msg
      end
    end
    messages << "</div>"
    messages.html_safe
  end

  def html_tag(&block)
      inner_content = capture(&block)
      
      content = <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
#{inner_content}
</html>
EOF
    content.html_safe
  end

  def head_tag(*stylesheets, &block)
    inner_content = capture(&block)
    content = <<EOF
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <meta http-equiv="Content-Script-Type" content="text/javascript; charset=utf-8" />
    <meta name="author" content="Nay" />
    <meta http-equiv="content-style-type" content="text/css" />
    #{csrf_meta_tags}
    #{stylesheet_link_tag *stylesheets.insert(0, 'application')}
    #{javascript_pack_tag :application}
    #{render :partial => "shared/google_analytics"}
    #{inner_content}
  </head>
EOF
    content.html_safe
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
    content.html_safe
  end

  # 通信欄
  def flash_notice
    if flash[:notice] || flash[:notice].to_s != ""
      return "<div id=\"notice\">#{h flash[:notice]}</div>".html_safe
    end
    ''
  end

  # 口座に注目したときの表記
  def display_account_entry(entry, style = nil)
    s =<<EOS
      <td class="date" #{style}>#{format_date entry.date}</td>
      <td class="number" #{style}>#{entry.daily_seq}</td>
      <td class="summary" #{style}>#{entry.summary}</td>
      <td class="account_deals_link">#{link_to '→', monthly_account_deals_path(:account_id => entry.account_id, :year => entry.date.year, :month => entry.date.month, :anchor => "e#{entry.id}")}</td>
      <td class="account" #{style}>#{entry.mate_account_name}</td>
      <td class="amount" #{style}>#{number_with_delimiter(entry.amount.abs) if entry.amount < 0}</td>
      <td class="amount" #{style}>#{number_with_delimiter(entry.amount) if entry.amount >= 0}</td>
EOS
    s.html_safe
  end
  def display_account_entry_header
    s = <<EOS
      <th class="date">年月日</th>
      <th> </th>
      <th class="summary">摘要</th>
      <th> </th>
      <th class="account"></th>
      <th class="amount">出金</th>
      <th>入金</th>
EOS
    s.html_safe
  end


  # optgroup を使わずに口座を選ばせるリストを表示する
  def select_account(object, method, asset_kinds, with_asset_type = true, options = {}, html_options = {})
    accounts = current_user.assets.where("asset_kind in (?)", asset_kinds.map{|k| k.to_s}).order(:sort_key)
    select(object, method, accounts.collect{|a| [with_asset_type ?  a.name_with_asset_type : a.name, a.id] }, options, html_options)
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
    return '' unless bgcolor.present?;
    style_content = "background-color: #{bgcolor};"
    return ('style="'+h(style_content)+'"').html_safe
  end

#  def format_deal(deal)
#    return "記入 #{deal.date}-#{deal.daily_seq}"
#  end

  # 帳簿系表示ヘルパー
  # 一行を表示する　(table.book の下で呼ばれることを前提とする)
  # :account があれば :name は自動で入れる :account はないこともある
  # @year, @month の存在を前提とする
  def book_line(contents = {})
    contents[:name] ||= contents[:account].try(:name)
    string = "<tr>\n"
    string += "<td>#{contents[:account] ? link_to(contents[:name], monthly_account_deals_path(:account_id => contents[:account].id, :year => @year.to_s, :month => @month.to_s), :class => 'account') : contents[:name]}</td>\n" if contents[:name]
    string += "<td class='percentage'>#{contents[:percentage]}%</td>\n" if contents[:percentage]
    string += "<td class='amount'>#{number_with_delimiter(contents[:amount])}</td>\n" if contents[:amount]
    string += "</tr>\n"
    string.html_safe
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

#  def load_menu(url)
#    Menues.side_menues.load(url)
#  end

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

end
