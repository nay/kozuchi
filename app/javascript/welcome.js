/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
$(() => $('#login_button').click(function(event){
  if ($('#login').val() ==='') {
    alert('ログインIDを入力してください。');
    return event.preventDefault();
  } else if ($('#password').val()==='') {
    alert('パスワードを入力してください。');
    return event.preventDefault();
  }
}));
