require "babel-polyfill"

console.log "Config:", config

{ language } = require "./languages"

WS = require "./ws"

m    = require "mithril"
papa = require "papaparse"

# todo: calculate line size
# todo: resize
# todo: parse time
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

	lineSize = await new Promise (resolve) ->
		tr = document.createElement "tr"
		td = document.createElement "td"
		td.innerHTML = "12345ABCabc"
		tr.appendChild td
		document.body.appendChild tr
		setTimeout ->
			resolve tr.clientHeight
			document.body.removeChild tr
		, 150

	class Main
		constructor: ->
			@count   = 0
			@start   = 0
			@maxHead = 0
			@lines   = []
			@visible = []

			@loadLinesCount().then (@count) =>
				console.log "Lines count:", @count
				m.redraw()

		loadLines: (start, end) ->
			return new Promise (resolve) =>
				ws.get("get", { start, end }).then (lines) =>
					{ data } = papa.parse lines
					resolve data

		loadLinesCount: ->
			return new Promise (resolve) =>
				ws.get("lines").then (lines) =>
					resolve lines

		scroll: (event) ->
			dom = event.target
			@scrollTop = dom.scrollY or dom.scrollTop

			scrollBottom = dom.clientHeight + @scrollTop

			topLine    = Math.min(Math.max(Math.floor(@scrollTop / lineSize), 0), @count)
			bottomLine = Math.max(Math.min(Math.floor(scrollBottom / lineSize), @count), 0) 

			@start = topLine
			@lines = await @loadLines topLine, bottomLine
			@visible = @lines[0..@lines.length - 3]

			m.redraw()

		view: ->
			m "div.table-root", { 
				onscroll: (event) => await @scroll event
				oncreate: (vnode) =>
					@updateInterval = setInterval =>
						await @scroll { target: vnode.dom }
						m.redraw()
					, 500
				onremove: (vnode) =>
					clearInterval @updateInterval
			},
				if @lines
					m "div.table", { style: height: (@count * lineSize) + "px" },
						m "table", { style: top: (@start * lineSize) + "px" }, [
							m "thead", [
								m "tr", language.headers.map (header) =>
									m "th", { 
										style: top: (@scrollTop - (@start * lineSize)) + "px"
										oncreate: (vnode) =>
											setTimeout =>
												head = vnode.dom.clientHeight
												if head > @maxHead
													@maxHead = head
											, 150

									}, header#.split("\n").map (line) -> m "span", [
										# line
										# m "br"
									# ]
							]
							m "tbody", [
								@lines.map (line) =>
									m "tr", line.map (cell) =>
										m "td", cell
							]
						]

	# mount
	root = document.getElementById "root"
	m.mount root, Main
