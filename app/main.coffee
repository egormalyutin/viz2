require "babel-polyfill"

console.log "Config:", config

{ language } = require "./languages"
WS = require "./ws"

Table   = require "./table"
Plots   = require "./plots"
Range   = require "./range"
Limiter = require "./limiter"

papa = require "papaparse"

m = require "mithril"

bus = require "./bus"

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
			@mode = "table"
			@linesCount = undefined
			@tableMode = true
			@loadingRange = false

		onvisible: (@visible) ->
			m.redraw()

		view: ->
			@table = m Table, { 
				ws, 
				onvisible: (visible) => 
					@onvisible visible
					@mode = "table"
				onlines: (@linesCount) =>
			}

			@range = if @linesCount
				m Range, {
					lines: @linesCount
					onchange: (start, end) =>
						@loadingRange = true
						m.redraw()
						data = await ws.get "get", { start, end }
						@visible = papa.parse(data).data
						@mode = "range"
						@loadingRange = false
						m.redraw()
				}

			@updateCount = @updateCount or @mode == "range"

			@plots = m Plots, {
				lines: @visible
				mode: @mode
				loading: @loadingRange
				onclick: (i) =>
					index = @table.state.lines.indexOf @visible[i]
					@table.state.light = index
					m.redraw()

				@updateCount
			}

			tablePad = m "div.pad.table-pad", @table
			plotsPad = m "div.pad", @plots
			rangePad = m "div.pad", @range

			m "div.main", [
				topPad = m "div.top-pad", [
					tablePad
					rangePad
				]
				m Limiter, { first: tablePad, second: plotsPad }
				plotsPad
				m "div.range-button", {
					onclick: =>
						@tableMode = not @tableMode
						topPad.dom.classList.toggle "select-right"
				},
					m "div.range-button-arrow", if @tableMode
						"↪"
					else
						"↩"
			]

	# mount
	root = document.getElementById "root"
	m.mount root, Main
