// with JQuery

jQuery(document).ready(function($){
  $('#user_and_today').click(function(){
    window.location.href = $(this).attr('link')
  })
});
