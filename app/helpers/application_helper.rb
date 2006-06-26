# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include LoginEngine
  
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
  
  # 円グラフのためのURLを表示する
  def pie_graph(resource_array, percentage_method, name_method, value_method = nil, total_value = nil)
    labels = ''
    values = ''
    begin
      for r in resource_array
        if percentage_method
          percentage = r.method(percentage_method).call
        else
          percentage = total_value != 0 ? (r.method(value_method).call * 100.0 / total_value).round : 0
        end
        next if percentage == 100 || percentage == 0
        values += percentage.to_s + ','
        labels += r.method(name_method).call + ','
      end
    
      if labels.count(',') > 1
        url = url_for(:controller=>'graph', :action=>'pie', :labels=>labels, :values=>values)
        return '<img src="' + url + ' />"'
      else
        p "values = #{values}"
        p "labels = #{labels}"
        return '<span>グラフは２つ以上の項目があるときに表示されます。</span>'
      end
    rescue => err
      return "<span>エラーのためグラフを表示できません。<br />#{err}<br />#{err.backtrace}</span>"
    end
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
  
  def <<(account)
    @accounts << account
  end
end


end
