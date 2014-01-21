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

@moneyCounter = new MoneyCounter
