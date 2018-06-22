require "babel-polyfill"

WS       = require "./ws"

m        = require "mithril"
papa     = require "papaparse"
debounce = require "debounce"

LINE_SIZE = 20 
FAULT     = LINE_SIZE / 5
VISIBLE   = 300

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

		loadLinesCount: ->
			ws.get("lines").then (@count) =>

		oninit: ->
			@count = 0
			@height = 0
			@visible = {}
			@lines = {}

			await Main.loadLinesCount.call(@)
			console.log "Lines count:", @count
			@height = (@count * LINE_SIZE)
			m.redraw()

		scroll: debounce (event) ->
			dom = event.target
			trueScrollTop    = dom.scrollY or dom.scrollTop
			trueScrollBottom = dom.clientHeight + trueScrollTop

			scrollTop    = Math.max trueScrollTop    - VISIBLE, 0
			scrollBottom = Math.min trueScrollBottom + VISIBLE, @height

			topLine    = Math.floor scrollTop    / LINE_SIZE
			bottomLine = Math.floor scrollBottom / LINE_SIZE

			@visible = {}

			Main.loadLines.call(@, topLine, bottomLine)
				.then =>
					for num, line of @lines
						num -= 0
						y = num * LINE_SIZE
						yBottom = y + LINE_SIZE

						if (yBottom < scrollTop) or (y > scrollBottom)
							delete @lines[num]

						if (y > trueScrollTop - FAULT) and (yBottom < trueScrollBottom + FAULT)
							@visible[num] = line
		, 10

		view: ->
			m "div.table-root", { 
				onscroll: (event) => Main.scroll.call @, event
				oncreate: (vnode) =>
					@updateInterval = setInterval =>
						Main.scroll.call @, { target: vnode.dom }
					, 500
				onremove: (vnode) ->
					clearInterval @updateInterval
			},
				m "div.table", { style: height: @height + "px" },
					m "table", mapObj(@lines, (line, num) ->
						return m "tr", { style: top: (LINE_SIZE * num) + "px" }, line.map (cell) ->
							m "td", cell
					)

	# mount
	root = document.getElementById "root"
	m.mount root, Main
