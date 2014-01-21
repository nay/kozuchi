$ ->
  $('#user_and_today').click ->
    window.location.href = $(@).attr('link')

  $('a[data-popup]').on('click', (e)->
      window.open(@href)
      e.preventDefault()
  )

@unifySummary = ->
  $('.entry_summary').hide()
  $('#deal_summary_frame').show()
  $('#deal_summary_mode, #deal_pattern_summary_mode').val('unify')

@splitSummary = ->
  $('#deal_summary_frame').hide()
  $('.entry_summary').show()
  $('#deal_summary_mode, #deal_pattern_summary_mode').val('split')
