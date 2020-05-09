/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS208: Avoid top-level this
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
$(function() {

  $('#user_and_today').click(function() {
    return window.location.href = $(this).attr('link');
  });

  $('a[data-popup]').on('click', function(e){
      window.open(this.href);
      return e.preventDefault();
  });

  // select.switcher が変更されたら、data-url-template の template 内の _SWITCHER_VALUE_ を置き換えてredirectする
  return $('select.switcher').change(function() {
    const url = $(this).data('url-template').replace("_SWITCHER_VALUE_", $(this).val());
    return location.href = url;
  });
});

// 月末の日を得る
endOfMonth = function(year, month) {
  if (!year || (year === '') || !month || (month === '')) {
    return null;
  }

  year = parseInt(year);
  month = parseInt(month);

  const nextYear = month === 12 ? year + 1 : year;
  const nextMonth = month === 12 ? 1 : month + 1;

  return new Date(nextYear, nextMonth - 1, 0).getDate();
};

$(() => $(document).on("click", "a.reason", function(event){
  const message = $(this).data("reason");
  if (message) { alert(message); }
  return event.preventDefault();
}));
