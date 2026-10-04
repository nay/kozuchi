module DealsHelper

  # 明細の一覧のパス。日があればその日で絞った一覧、なければ月の一覧
  # 年月日は date:（VagueDate か Date）か、year:, month:, day:（day は省略可）のどちらかで指定する
  # account_id - 指定するとその口座の一覧、しなければ総合の一覧
  def deals_list_path(date: nil, year: nil, month: nil, day: nil, account_id: nil, **options)
    raise ArgumentError, "date: と year:, month:, day: は同時に指定できません" if date && (year || month || day)

    date = VagueDate.from(date || [year, month, day])
    date_params = {year: date.year, month: date.month, **options}
    if date.day
      account_id ? daily_account_deals_path(account_id: account_id, day: date.day, **date_params) : daily_deals_path(day: date.day, **date_params)
    else
      account_id ? monthly_account_deals_path(account_id: account_id, **date_params) : monthly_deals_path(**date_params)
    end
  end

  # 月の一覧のパスのテンプレート。_YEAR_, _MONTH_ を年月に置き換えて使う
  def monthly_deals_list_path_template(account_id)
    account_id ? monthly_account_deals_path(account_id: account_id, year: '_YEAR_', month: '_MONTH_') : monthly_deals_path(year: '_YEAR_', month: '_MONTH_')
  end

  # 年月日は deals_list_path と同じく、date: か year:, month:, day: で指定する
  # data - リンクに追加する data 属性
  def account_button(account, date: nil, year: nil, month: nil, day: nil, data: {})
    link_to truncate(account.name, length: 10), deals_list_path(date: date, year: year, month: month, day: day, account_id: account.id), class:  %w(btn btn-default monthly_deals_link), data: {url_template: monthly_deals_path(year: '_YEAR_', month: '_MONTH_')}.merge(data)
  end

  def money_count_field(name, caption)
    content_tag :div, class: %w(field) do
      html = label_tag name, caption
      html << text_field_tag(name, size: 2, autocomplete: 'off')
      html << content_tag(:span, '枚')
    end
  end

  # 総合の一覧の中の、明細（deal）の行へのリンク。その明細の日で絞った一覧に移る
  # deal_or_entry - 明細（Deal）か、明細の中の記入（Entry）
  def icon_to_deal(deal_or_entry)
    deal_id = deal_or_entry.is_a?(Entry::Base) ? deal_or_entry.deal_id : deal_or_entry.id
    link_to '→', deals_list_path(date: deal_or_entry.date, anchor: "d#{deal_id}")
  end

  def write_hiddens_and_get_simple_deal_procs(f, options = {})
    amount_field_proc = nil
    debtor_account_field_proc = nil
    creditor_account_field_proc = nil
    f.fields_for :debtor_entries do |e|
      fixed_account = options[:debtor_account_fixed]
      fixed_account ||=  e.object.account if e.object.settlement_attached?
      
      if e.object.marked_for_destruction?
        concat(e.hidden_field :_delete, :value => '1')
      else
        amount_unchangable = e.object.settlement_attached?
        amount_field_proc = lambda{|tabindex | (e.text_field(:amount, {:size => "8", :disabled => amount_unchangable, :class => "amount#{amount_unchangable ? '' : ' pattern_field'}", :tabindex => tabindex}.merge(amount_unchangable ? {:id => nil} : {}))) + (amount_unchangable ? e.hidden_field(:amount, :class => 'pattern_field') : '')}
        debtor_account_field_proc = if fixed_account
          lambda{|tabindex|
            ("<input type='text' disabled='true' class='readonly' value='#{fixed_account.name}' tabindex='#{tabindex}' />" +
            e.hidden_field(:account_id, :value => fixed_account.id, :class => 'pattern_field')).html_safe
          }
        else
          lambda{|tabindex| (e.select :account_id, grouped_options_for_select(@user.accounts.active.grouped_options(false), e.object.account_id), {}, :tabindex => tabindex, :class => 'pattern_field').html_safe }
        end
      end
    end

    f.fields_for :creditor_entries do |e|
      fixed_account = options[:creditor_account_fixed]
      fixed_account ||=  e.object.account if e.object.settlement_attached?

      if e.object.marked_for_destruction?
        concat(e.hidden_field :_delete, :value => '1')
      else
        creditor_account_field_proc = if fixed_account
          lambda{|tabindex|
            ("<input type='text' disabled='true' class='readonly' value='#{fixed_account.name}' tabindex='#{tabindex}' />" +
            e.hidden_field(:account_id, :value => fixed_account.id, :class => 'pattern_field')).html_safe
          }
        else
          lambda{|tabindex| (e.select :account_id, grouped_options_for_select(@user.accounts.active.grouped_options(true), e.object.account_id), {}, :tabindex => tabindex, :class => 'pattern_field').html_safe }
        end
      end
    end

    return amount_field_proc, debtor_account_field_proc, creditor_account_field_proc
  end


  # frame - Turbo Frame の中に置く登録フォームのとき、その Frame の id
  #   Frame の中身を入れ替えても、日付の欄と記入フォーム（#deal_forms）は入れ替えずに残す
  #   日付の欄の年月日を変えたら、month_url_template の _YEAR_, _MONTH_ を置き換えた月の一覧（日があればその日で絞った一覧）の内容に Frame の中身を入れ替える
  #   日の欄のすぐ右にクリアボタンを置き、押したら表示中の年月の月の一覧をページごと開き直す。日が空のときは薄く表示する
  def deal_editor(start_tab_index = 1, year = nil, month = nil, day = nil, frame: nil, month_url_template: nil, &block)
    tab_index = start_tab_index
    datebox_options = {class: 'datebox'}
    if frame
      datebox_options[:id] = 'new_deal_datebox'
      datebox_options[:data] = {
        turbo_permanent: true,
        controller: 'deal-date',
        action: 'change->deal-date#navigate input->deal-date#updateClearButton turbo:visit@document->deal-date#visitStarted turbo:before-frame-render@document->deal-date#follow turbo:before-render@document->deal-date#follow',
        deal_date_frame_value: frame,
        deal_date_url_template_value: month_url_template,
        deal_date_year_value: year,
        deal_date_month_value: month,
        deal_date_day_value: day
      }
    end
    target = ->(name) { frame ? {data: {deal_date_target: name}} : {} }
    text = ''.html_safe
    # 日付の欄は入れ替えずに残るので、移動先の画面の年月日は、入れ替えられるこちらの要素から受け取る
    text << content_tag(:div, nil, id: 'new_deal_datebox_source', hidden: true, data: {year: year, month: month, day: day}) if frame
    text << content_tag(:div, **datebox_options) do
      content_tag :form, class: 'datebox_form' do
        d = ''
        d << text_field(:date, :year, {:size => 4, :max_length => 4, :tabindex => tab_index, :value => year}.merge(target.call('year')))
        tab_index += 1
        d << text_field(:date, :month, {:size => 2, :max_length => 2, :tabindex => tab_index, :value => month}.merge(target.call('month')))
        tab_index += 1
        d << text_field(:date, :day, {:size => 2, :max_length => 2, :tabindex => tab_index, :value => day}.merge(target.call('day')))
        d << ' '
        d << content_tag(:a, 'クリア', class: 'clear_deal_form_button', data: {action: 'deal-date#clear', deal_date_target: 'clear'}) if frame
        d << content_tag(:a, '月末', :class => 'end_of_month_button')
        d.html_safe
      end
    end
    deal_forms_options = {id: "deal_forms"}
    deal_forms_options[:data] = {turbo_permanent: true} if frame
    text << content_tag(:div, capture(&block), **deal_forms_options)
    text.html_safe
  end

  # 記入モード切り替えのタブ(div)を出力する
  # link_html_options に :class が渡されることは想定していない
  def deal_tab(caption, url, current_caption, link_html_options = {})
    selected = current_caption == true || current_caption == caption
    link_to caption, url, {class: %w(btn btn-default pull-right) + (selected ? %w(active) : []) }.merge(link_html_options)
  end

  def deal_form(current_caption, options = {}, &block)
    text = "<div id='tabwindow'>"
    text << render(:partial => 'deal_tabs', :locals => {:deal => @deal, :current_caption => current_caption})
    text << "<div id='tabsheet' class='tabsheet'>"
    html_options = options.delete(:html) || {}
    text << form_for(@deal, :as => :deal, :url => options[:url], :html => {:id => 'deal_form'}.merge(html_options)) do |f|
      h = f.hidden_field(:year)
      h << f.hidden_field(:month)
      h << f.hidden_field(:day)
      h << capture(f, &block)
#      yield f
      h.html_safe
    end
    text << "</div>"
    text << "</div>"
    text.html_safe
  end

  def datebox
    content_tag :div, class: "datebox" do
      content_tag :form, class: "datebox_form" do
        text_field(:date, :year, :size => 4, :max_length => 4, :tabindex => 1) +
          text_field(:date, :month, :size => 2, :max_length => 2, :tabindex => 2) +
          text_field(:date, :day, :size => 2, :max_length => 2, :tabindex => 3)
      end
    end
  end

end
