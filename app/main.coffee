require "babel-polyfill"

WS       = require "./ws"

m        = require "mithril"
papa     = require "papaparse"
debounce = require "debounce"

CHUNK_SIZE = 100

LINE_SIZE = 20 

isVisible = (e) ->
	return !!(e.offsetWidth || e.offsetHeight || e.getClientRects().length)

mapObj = (obj, f) ->
	ret = []
	for name, prop of obj
		ret.push f prop, name
	return ret

do ->
	ws = await new WS config.ws

	Main =
		loadLines: (start, end) ->
			ws.get("get", { start, end }).then (lines) =>
				{ data } = papa.parse lines
				i = start
				for line in data
					@lines[i] ?= line
					i++

				m.redraw()

		loadLinesCount: ->
			ws.get("lines").then (@count) =>

		oninit: ->
			@count = 0

			@lines = {}

			Main.loadLines.call(@, 0, 100)

			Main.loadLinesCount.call(@)
				.then =>
					console.log @count
					document.body.style.height = (@count * LINE_SIZE) + "px"

			@bottomListener = debounce =>
				scrollTop    = window.scrollY
				scrollBottom = window.innerHeight + window.scrollY

				if scrollBottom >= document.body.offsetHeight - 300
					Main.loadLines.call(@)

				topLine    = Math.floor scrollTop    / LINE_SIZE
				bottomLine = Math.floor scrollBottom / LINE_SIZE
				Main.loadLines.call(@, topLine, bottomLine)
			, 20

			window.addEventListener "scroll", @bottomListener

		onremove: ->
			window.removeEventListener "scroll", @bottomListener

		view: ->
			m "table", mapObj(@lines, (line, num) ->
				return m "tr", { style: top: (LINE_SIZE * num) + "px" }, line.map (cell) ->
					m "td", cell
			)

	# mount
	root = document.getElementById "root"
	m.mount root, Main
