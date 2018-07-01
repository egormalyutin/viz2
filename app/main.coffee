require "babel-polyfill"

console.log "Config:", config

{ language } = require "./languages"
WS = require "./ws"

Table   = require "./table"
Plots   = require "./plots"
Limiter = require "./limiter"

m = require "mithril"

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
			@lines = []
			@doms = []

		onvisible: (@visible) ->
			m.redraw()

		view: ->
			@table = m Table, { 
				ws, 
				onvisible: (visible) => 
					@onvisible visible
			}

			@plots = m Plots, {
				lines: @visible
				onclick: (i) =>
					index = @table.state.lines.indexOf @visible[i]
					@table.state.light = index
					m.redraw()
			}

			tablePad = m "div.pad", @table
			plotsPad = m "div.pad", @plots

			m "div.main", [
				tablePad
				m Limiter, { first: tablePad, second: plotsPad }
				plotsPad
			]

	# mount
	root = document.getElementById "root"
	m.mount root, Main
