$(document)
  .on('turbolinks:request-end', () => {
    $('style').each((i, el) => {
      if (el.innerHTML.indexOf('.b-adaptive-css-background') !== -1) {
        el.parentNode.removeChild(el)
      }
    })
  })
