

bgColor = new QueryInterface
	key: "bgColor" # key used in address bar: ?bgColor=28affa
	default: "28affa" # fallback / initial color = 'Framer blue' (hex color)

Canvas.backgroundColor = bgColor.value

window.addEventListener 'click', ->
	bgColor.value = Canvas.backgroundColor = Utils.randomColor().toHex()


