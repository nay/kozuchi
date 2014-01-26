$ ->
  $('#user_and_today').click ->
    window.location.href = $(@).attr('link')

  $('a[data-popup]').on('click', (e)->
      window.open(@href)
      e.preventDefault()
  )

# 月末の日を得る
@endOfMonth = (year, month) ->
  if !year || year == '' || !month || month == ''
    return null

  year = parseInt(year)
  month = parseInt(month)

  nextYear = if month == 12 then year + 1 else year
  nextMonth = if month == 12 then 1 else month + 1

  new Date(nextYear, nextMonth - 1, 0).getDate()
