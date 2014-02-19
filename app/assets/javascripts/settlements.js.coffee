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
    $('#target_deals').load($('#target_deals_form').data('url'), $('#target_deals_form').serialize())

  $('#select_credit_account select.refresh_targets').change(refreshTargets)

  $('#select_credit_account button.refresh_targets').click ->
    refreshTargets()
    return false

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
