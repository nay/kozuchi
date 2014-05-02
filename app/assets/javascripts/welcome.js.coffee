$ ->
  $('#login_button').click (event)->
    if $('#login').val() ==''
      alert('ログインIDを入力してください。')
      event.preventDefault()
    else if $('#password').val()==''
      alert('パスワードを入力してください。')
      event.preventDefault()
