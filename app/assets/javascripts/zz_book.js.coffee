# 残高編集時に金額を計算する
class MoneyCounter
  money_counting_fields: ['man', 'gosen', 'nisen', 'sen', 'gohyaku', 'hyaku', 'gojyu', 'jyu', 'go', 'ichi']
  money_counting_amounts: [10000, 5000, 2000, 1000, 500, 100, 50, 10, 5, 1]
  count: ->
    amount = 0
    for i in [0..@money_counting_fields.length-1]
      v = jQuery('#' + @money_counting_fields[i]).val()
      if v != ''
        amount += parseInt(v) * @money_counting_amounts[i]
    jQuery('#deal_balance').val(amount)

@moneyCounter = new MoneyCounter

# 月末の日を得る
@endOfMonth = (year, month) ->
  if !year || year == '' || !month || month == ''
    return null

  year = parseInt(year)
  month = parseInt(month)

  nextYear = if month == 12 then year + 1 else year
  nextMonth = if month == 12 then 1 else month + 1

  new Date(nextYear, nextMonth - 1, 0).getDate()
