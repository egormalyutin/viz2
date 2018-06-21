require "babel-polyfill"

WS = require "./ws"
m  = require "mithril"

do ->
	ws = await new WS config.ws

	Main =
		oninit: ->
			@count = 0
			console.log await ws.get("lines")

		view: ->
			m "h1", "sdsds"

	# mount
	root = document.getElementById "root"
	m.mount root, Main
