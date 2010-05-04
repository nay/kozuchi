module DealsHelper

  # 仕訳帳中の指定された deal を示すURLを生成する
  # 以下のいずれかの引数をとる
  # * dealオブジェクトのみ
  # * entryオブジェクトのみ
  # * year, month, deal_id の３つ
  def icon_to_deal_in_monthly(*args)
    year, month, deal_id = case args.first
    when Deal::Base
      [args.first.year, args.first.month, args.first.id]
    when Entry::Base
      [args.first.year, args.first.month, args.first.deal_id]
    else
      raise "3 parameters required" unless args.size == 3
      args
    end
    link_to '→', monthly_deals_path(:year => year, :month => month, :updated_deal_id => deal_id, :anchor => deal_id.to_s)
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
        amount_field_proc = lambda{|tabindex | (e.text_field(:amount, :size => "8", :disabled => e.object.settlement_attached?, :class => 'amount', :tabindex => tabindex)) + (e.object.settlement_attached? ? e.hidden_field(:amount) : '')}
        debtor_account_field_proc = if fixed_account
          lambda{|tabindex|
            "<input type='text' disabled='true' class='readonly' value='#{fixed_account.name}' tabindex='#{tabindex}' />" +
            e.hidden_field(:account_id, :value => fixed_account.id)
          }
        else
          lambda{|tabindex| e.select :account_id, grouped_options_for_select(@user.accounts.grouped_options(false), e.object.account_id), :tabindex => tabindex}
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
            "<input type='text' disabled='true' class='readonly' value='#{fixed_account.name}' tabindex='#{tabindex}' />" +
            e.hidden_field(:account_id, :value => fixed_account.id)
          }
        else
          lambda{|tabindex| e.select :account_id, grouped_options_for_select(@user.accounts.grouped_options(true), e.object.account_id), :tabindex => tabindex}
        end
      end
    end

    return amount_field_proc, debtor_account_field_proc, creditor_account_field_proc
  end


  def deal_editor(start_tab_index = 1, year = nil, month = nil, day = nil)
    tab_index = start_tab_index
    text = content_tag(:div, :id => 'datebox') do
      content_tag :form, :id => 'datebox_form' do
        text = ''
        text << text_field(:date, :year, :size => 4, :max_length => 4, :tabindex => tab_index, :value => year)
        tab_index += 1
        text << text_field(:date, :month, :size => 2, :max_length => 2, :tabindex => tab_index, :value => month)
        tab_index += 1
        text << text_field(:date, :day, :size => 2, :max_length => 2, :tabindex => tab_index, :value => day)
        text
      end
    end
    text << content_tag(:div, :id => "deal_forms") do
      yield
    end
    concat(text)
  end

  def deal_tab(caption, url, current_caption, html_options = {})
    content_tag :div, :class => (current_caption == true || current_caption == caption) ? "selectedtab" : "tab" do
      if current_caption == true || current_caption == caption
        caption
      else
        link_to_remote caption, {:update => "deal_forms", :url => url, :method => :get, :before => "if($('notice')){ $('notice').hide();}"}, html_options
      end
    end
  end

  def deal_form(current_caption, options = {})
    concat("<div id='tabwindow'>")
    concat(render :partial => 'deal_tabs', :locals => {:deal => @deal, :current_caption => current_caption})
    concat("<div id='tabsheet' class='tabsheet'>")
    merged_before = "$('deal_year').value = $('date_year').value; $('deal_month').value = $('date_month').value; $('deal_day').value = $('date_day').value;"
    merged_before << options.delete(:before) if options[:before]
    remote_form_for :deal, @deal, {:before => merged_before}.merge(options) do |f|
      concat(f.hidden_field :year)
      concat(f.hidden_field :month)
      concat(f.hidden_field :day)
      yield f
    end
    concat("</div>")
    concat("</div>")
  end

  def datebox
    content_tag :div, :id => "datebox" do
      content_tag :form, :id => "datebox_form" do
        text_field(:date, :year, :size => 4, :max_length => 4, :tabindex => 1) +
          text_field(:date, :month, :size => 2, :max_length => 2, :tabindex => 2) +
          text_field(:date, :day, :size => 2, :max_length => 2, :tabindex => 3)
      end
    end
  end

end
