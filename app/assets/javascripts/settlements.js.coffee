class @Settlement
  contsructor: () ->
    @creditorSum = 0
    @debtorSum = 0
  toggle: (checkbox, amount) ->
    if checkbox.checked
      if amount < 0
        @debtorSum -= amount
      else
        @creditorSum += amount
      $(checkbox.parentNode.parentNode).removeClass('disabled')
    else
      if amount < 0
        @debtorSum += amount
      else
        @creditorSum -= amount
      $(checkbox.parentNode.parentNode).addClass('disabled')
    $('#debtor_sum').html(numToFormattedString(@debtorSum))
    $('#creditor_sum').html(numToFormattedString(@creditorSum))

    if @debtorSum > @creditorSum
      $('#target_description').html('に');
      $('#result').html(' から ' + numToFormattedString(@debtorSum - @creditorSum) + '円 を入金する。')
    else
      $('#target_description').html('から');
      $('#result').html(' に ' + numToFormattedString(@creditorSum - @debtorSum) + '円 が入金される。')

numToFormattedString = (num) ->
  str = num.toString()
  result = ''
  count = 0
  for i in [str.length-1..0]
    result = str.charAt(i) + result
    break if str.charAt(i) == '-' || i == 0
    count += 1
    if (count % 3) == 0
      result = ',' + result
  result

$ ->
  refreshTargets = ->
    $('#target_deals').load($('#target_deals_form').data('url'), $('#target_deals_form').serialize(), ->
      settlement.debtorSum = $('#settlement_sums').data("debtor-sum")
      settlement.creditorSum = $('#settlement_sums').data("creditor-sum")
    )

  $('#select_credit_account select.account_selector').change ->
    location.href = $(@).data("url-template").replace("_ACCOUNT_ID_", $(@).val())

  $('#target_deals').on('click', 'a.selectAll', (e)->
    $('table.book input[type=checkbox]').each ->
      $(@).click() if !@checked
    e.preventDefault()
  )
  $('#target_deals').on('click', 'a.clearAll', (e)->
    $('table.book input[type=checkbox]').each ->
      $(@).click() if @checked
    e.preventDefault()
  )

  adjustDayOptions = (option_selector, lastDay) ->
    $(option_selector).each ->
      if parseInt($(@).val()) > lastDay
        $(@).remove()
    day = parseInt($(option_selector).last().val())
    while day < lastDay
      day += 1
      $(option_selector).last().after("<option value='" + day + "'>" + day + "</option>")

  # 選択された年、月に応じて日の選択肢の範囲を更新する
  refreshDayOptions = ->
    # 開始日
    startYear = $('#start_date_year').val()
    startMonth = $('#start_date_month').val()
    adjustDayOptions('#start_date_day option', new Date(parseInt(startYear), parseInt(startMonth), 0).getDate())

    # 終了日
    # TODO: 開始日より前を選べないようにもしたい
    endYear = $('#end_date_year').val()
    endMonth = $('#end_date_month').val()
    adjustDayOptions('#end_date_day option', new Date(parseInt(endYear), parseInt(endMonth), 0).getDate())

  # 指定された期間にあわせて月ナビゲーターの色を更新する
  refreshMonthNavigator = ->
    $("tr.month").removeClass('selected')

    startYear = $('#start_date_year').val()
    startMonth = $('#start_date_month').val()
    endYear = $('#end_date_year').val()
    endMonth = $('#end_date_month').val()
    if (new Date(parseInt(startYear), parseInt(startMonth)-1, 1)) <= (new Date(parseInt(endYear), parseInt(endMonth)-1, 1))
      startYear = parseInt(startYear)
      startMonth = parseInt(startMonth)
      endYear = parseInt(endYear)
      endMonth = parseInt(endMonth)
      $("tr.month").each ->
        year = $(@).data('year')
        month = $(@).data('month')
        if (year > startYear || (year == startYear && month >= startMonth)) && (year < endYear || (year == endYear && month <= endMonth))
          $(@).addClass('selected')

  onSpanChange = ->
    refreshDayOptions()
    refreshMonthNavigator()
    refreshTargets()

  refreshMonthNavigator()
  refreshDayOptions()

  $('#start_date_year').change(onSpanChange)
  $('#start_date_month').change(onSpanChange)
  $('#start_date_day').change(onSpanChange)
  $('#end_date_year').change(onSpanChange)
  $('#end_date_month').change(onSpanChange)
  $('#end_date_day').change(onSpanChange)

  # まだ選択されていない領域がクリックされたら、範囲が月まで選択されていれば、近い方の端を伸ばす。
  # 選択されている領域がクリックされたら、その月のみが選択された状態にする。
  $('#month_navigator_frame tr.month').click ->
    year = $(@).data('year')
    month = $(@).data('month')

    startYear = $('#start_date_year').val()
    startMonth = $('#start_date_month').val()
    endYear = $('#end_date_year').val()
    endMonth = $('#end_date_month').val()

    if (new Date(parseInt(startYear), parseInt(startMonth)-1, 1)) <= (new Date(parseInt(endYear), parseInt(endMonth)-1, 1))
      startYear = parseInt(startYear)
      startMonth = parseInt(startMonth)
      endYear = parseInt(endYear)
      endMonth = parseInt(endMonth)

      # 開始より以前をクリック
      if year < startYear || (year == startYear && month < startMonth)
        $('#start_date_year').val(year)
        $('#start_date_month').val(month)
        $('#start_date_day').val(1)
      else if year > endYear || (year == endYear && month > endMonth)
        $('#end_date_year').val(year)
        $('#end_date_month').val(month)
        $('#end_date_day').val((new Date(year, month, 0)).getDate())
      else
        $('#start_date_year').val(year)
        $('#start_date_month').val(month)
        $('#start_date_day').val(1)
        $('#end_date_year').val(year)
        $('#end_date_month').val(month)
        $('#end_date_day').val((new Date(year, month, 0)).getDate())

      onSpanChange()
