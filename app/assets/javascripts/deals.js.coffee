# 残高編集時に金額を計算する
class MoneyCounter
  fields: ['man', 'gosen', 'nisen', 'sen', 'gohyaku', 'hyaku', 'gojyu', 'jyu', 'go', 'ichi']
  amounts: [10000, 5000, 2000, 1000, 500, 100, 50, 10, 5, 1]
  count: ->
    amount = 0
    for i in [0..@fields.length-1]
      v = $('#' + @fields[i]).val()
      if v != ''
        amount += parseInt(v) * @amounts[i]
    $('#deal_balance').val(amount)

# 更新された行のスタイリング

addClassToUpdatedline = ->
  if location.hash.match(/^#e?[0-9]+$/)
    updatedTr = $("tr:has(*[id='" + location.hash.replace('#', '') + "'])")
    updatedTr.addClass("updated_line")
    # 複数行がまとめられている場合のため

    while (nextTr = updatedTr.next("tr:not(:has(td.date))")).size() > 0
      nextTr.addClass("updated_line")
      updatedTr = nextTr

clearUpdateLine = ->
  $("tr").removeClass("updated_line")

$ ->
  # hide notice
  hideNotice = ->
    $('#notice').hide()

  # deal_tab
  $(document).on('click', '#deal_forms a.deal_tab', ->
    hideNotice()
    $('#deal_forms').load(this.href)
    return false
  )

  # deal_form
  $(document).on('submit', '#deal_form', ->
    # 日付のチェック
    if $('#date_day').val() == '' || $('#date_month').val() == '' || $('#date_year').val() == ''
      alert('日付を入れてください。')
      return false

    # 日付の読み取り
    $('#deal_year').val($('#date_year').val())
    $('#deal_month').val($('#date_month').val())
    $('#deal_day').val($('#date_day').val())

    # 金額のチェック
    amounts = $('input.amount')
    if amounts.size() > 0 && $.grep(amounts.get(), (amount, index)-> $(amount).val() != '').length == 0
      alert('金額を入力してください。')
      return false

    # 記入登録/更新を試みる
    $.post(@action, $(@).serializeArray(), (result)->
      if result.error_view
        $('#deal_forms').empty()
        $('#deal_forms').append(result.error_view)
      else
        resultUrl = $('#deal_form').data("result-url").replace(/_YEAR_/, result.year).replace(/_MONTH_/, result.month)
        resultUrlWithHash = resultUrl + "#" + result.id
        prevUrl = location.pathname
        prevSearch = location.search
        if prevSearch && prevSearch != ""
          prevUrl += "?" + prevSearch
        location.assign(resultUrlWithHash)
        # NOTE: assign しても location.pathname などが古いケースがあるため、resultUrlベースで用意して比較している
        if resultUrl == prevUrl
          location.reload()
    , 'JSON')
    return false # 通常の Form 動作は行わない
  )

  # a.edit_click
  $(document).on('click', 'a.edit_deal', (event)->
    $tr = $(@).closest('tr')
    if $tr.hasClass('edit_deal_row')
      $tr = $tr.prev()
    $('.edit_deal_row').remove()
    while !$tr.hasClass('last_entry')
      $tr = $tr.next()
    $tr.after("<tr class='edit_deal_row'><td colspan='12'></td></tr>")
    $(".edit_deal_row td").load(@href)
    event.preventDefault()
  )

  # a.add_entry_fields
  $(document).on('click', 'a.add_entry_fields', ->
    $('#deal_forms').load(@href, $(@).closest('form').serializeArray())
    return false
  )

  $(document).on('click', 'a.split_summary', ->
    $('#deal_summary_frame').hide()
    $('.entry_summary').show()
    $('#deal_summary_mode, #deal_pattern_summary_mode').val('split')
    false
  )

  $(document).on('click', 'a.unify_summary', ->
    $('.entry_summary').hide()
    $('#deal_summary_frame').show()
    $('#deal_summary_mode, #deal_pattern_summary_mode').val('unify')
    false
  )

  $(document).on('click', '#count_money_button', ->
    moneyCounter = new MoneyCounter
    moneyCounter.count()
    return false
  )

  $(document).on('click', 'a.end_of_month_button', ->
    day = endOfMonth($('#date_year').val(), $('#date_month').val())
    $('#date_day').val(day) if (day)
    return false
  )

  addClassToUpdatedline()

  $(window).hashchange ->
    clearUpdateLine()
    addClassToUpdatedline()

  # 登録日時などの表示

  $(document).on('mouseover', 'td.number', -> $('.timestamps', this).show())

  $(document).on('mouseout', 'td.number', -> $('.timestamps', this).hide())

  # 日ナビゲーション

  $('.for_deal_editor').on('click', '#day_navigator td.day a', (event)->
    $('input#date_day').val($(@).data('day'))
    event.preventDefault()
  )

  # カレンダー（月表示）

  $('.for_monthly_deals #calendar').change (event, month)->
    url = $('#month_submit_form').attr('action')
    url = url.replace('_YEAR_', month.year)
    url = url.replace('_MONTH_', month.month)
    $('#month_submit_form').attr('action', url)
    $('#month_submit_form').get(0).submit()

  # カレンダー（登録フォーム）

  $('.for_deal_editor #calendar').change (event, month) ->
    $('input#date_year').val(month.year)
    $('input#date_month').val(month.month)
    today = new Date()
    if today.getFullYear() == month.year && today.getMonth() + 1 == month.month
      day = today.getDate()
    else
      day = ''
    $('input#date_day').val(day)
    url = $('#day_navigator').data('url')
    url = url.replace('_YEAR_', month.year)
    url = url.replace('_MONTH_', month.month)
    $('#day_navigator_frame').load(url)

  # 今日ボタン （登録フォーム）
  $('.for_deal_editor #today').click (event) ->
    today = new Date
    document.calendar.selectMonth(today.getFullYear(), today.getMonth()+1, true)
    event.preventDefault()
