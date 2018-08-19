document.addEventListener 'turbolinks:load', ->
  if App.turbolinks || App.mobile
    $('a.zoom-image').attr("target","_blank")
  else
    $('a.zoom-image').fluidbox
      overlayColor: "#FFF"
      closeTrigger: [ {
        selector: 'window'
        event: 'scroll'
      } ]
