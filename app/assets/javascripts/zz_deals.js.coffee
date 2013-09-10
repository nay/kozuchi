jQuery(document).ready ($)->
  # hide notice
  hideNotice = ->
    $('#notice').hide()

  # deal_tab
  $('#deal_forms').on('click', 'a.deal_tab', ->
    hideNotice()
    $('#deal_forms').load(this.href)
    return false
  )

