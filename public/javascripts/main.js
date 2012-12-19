// with JQuery

jQuery(document).ready(function($){
  $('#user_and_today').click(function(){
    window.location.href = $(this).attr('link')
  })

  $('a[data-popup]').live('click', function(e) {
      window.open(this.href);
      e.preventDefault();
   });

});

function unifySummary() {
  jQuery('.entry_summary').hide()
  jQuery('#deal_summary_frame').show()
  jQuery('#deal_summary_mode, #deal_pattern_summary_mode').val('unify')
}

function splitSummary() {
  jQuery('#deal_summary_frame').hide()
  jQuery('.entry_summary').show()
  jQuery('#deal_summary_mode, #deal_pattern_summary_mode').val('split')
}