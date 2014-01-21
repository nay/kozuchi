$ ->
  $('#user_and_today').click ->
    window.location.href = $(@).attr('link')

  $('a[data-popup]').on('click', (e)->
      window.open(@href)
      e.preventDefault()
  )
