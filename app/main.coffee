require "babel-polyfill"

console.log "Config:", config

{ language } = require "./languages"
WS = require "./ws"

Table = require "./table"
Plots = require "./plots"

m    = require "mithril"

# todo: resize
# todo: watch

isVisible = (e) ->
	return !!(e.offsetWidth || e.offsetHeight || e.getClientRects().length)

mapObj = (obj, f) ->
	ret = []
	for name, prop of obj
		ret.push f prop, name
	return ret

i = 0

do ->
	ws = await new WS config.ws

	class Main
		constructor: ->
			@visible = []

		onvisible: (@visible) ->
			window.visible = @visible

		view: ->
			m "div.main", [
				m Table, { ws, onvisible: (visible) => @onvisible visible }
				m Plots, { lines: @visible }
			]

	# mount
	root = document.getElementById "root"
	m.mount root, Main
