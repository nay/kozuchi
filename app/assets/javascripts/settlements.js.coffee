jQuery(document).ready ($)->

  refreshTargets = ->
    $('#target_deals').load($('#target_deals_form').data('url'), $('#target_deals_form').serialize())

  $('#select_credit_account select.refresh_targets').change(refreshTargets)

  $('#select_credit_account button.refresh_targets').click ->
    refreshTargets()
    return false
