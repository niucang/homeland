document.addEventListener 'turbolinks:load', ->
  $('.nav-link').click (e) ->
    $('.row.login .nav-link').removeClass('active')
    $(this).addClass('active')
    if $('.password-login').hasClass('active')
      $('.login-password').show()
      $('.qrcode').hide()
    else
      $('.login-password').hide()
      $('.qrcode').show()
