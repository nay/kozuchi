jQuery(document).ready ($)->
  # hide notice
  hideNotice = ->
    $('#notice').hide()

  # deal_tab
  $(document).on('click', '#deal_forms a.deal_tab', ->
    hideNotice()
    $('#deal_forms').load(this.href)
    return false
  )

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
    $amounts = $('input.amount')
    if $amounts.size() > 0 && $.grep($amounts.get(), (amount, index)-> $(amount).val() != '').size() == 0
      alert('金額を入力してください。')
      return false

    # 記入登録/更新を試みる
    $.post(@action, $(@).serializeArray(), (result)->
      if result.error_view
        $('#deal_forms').empty()
        $('#deal_forms').append(result.error_view)
      else
        result_url = $('#deal_form').data("result-url").replace(/_YEAR_/, result.year).replace(/_MONTH_/, result.month)
        location.href = result_url + "?updated_deal_id=" + result.id
    , 'JSON')
    return false # 通常の Form 動作は行わない
  )
