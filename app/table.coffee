m = require "mithril"

{ language } = require "./languages"
bus = require "./bus"

papa = require "papaparse"

class Table
		constructor: ->
			@count   = 0
			@start   = 0
			@maxHead = 0
			@lines   = []
			@visible = []
			@light   = -1

		oninit: (vnode) ->
			calc = => new Promise (resolve) ->
				table = document.createElement "table"
				tr = document.createElement "tr"
				td = document.createElement "td"

				tr.classList.add "calc-line-size"

				td.innerHTML = "12345ABCabc"
				tr.appendChild td
				table.appendChild tr
				document.body.appendChild tr
				
				setTimeout ->
					resolve tr.clientHeight
					document.body.removeChild tr
				, 150

			@lineSize = await calc()

			bus.on "resize", =>
				@lineSize = await calc()
				m.redraw()

			vnode.attrs.ws.on "lines", (@count) =>

			vnode.attrs.ws.send "lines"
			console.log "Lines count:", await vnode.attrs.ws.receive("lines")

			m.redraw()

		loadLines: (vnode, start, end) ->
			return new Promise (resolve) =>
				vnode.attrs.ws.get("get", { start, end }).then (lines) =>
					{ data } = papa.parse lines
					resolve data

		scroll: (vnode, event) ->
			@light = -1

			dom = event.target
			@scrollTop = dom.scrollY or dom.scrollTop
			@scrollBottom = dom.clientHeight + @scrollTop

			topLine    = Math.min(Math.max(Math.floor(@scrollTop / @lineSize), 0), @count)
			bottomLine = Math.max(Math.min(Math.floor(@scrollBottom / @lineSize), @count), 0) 

			@start = topLine
			@lines = await @loadLines vnode, topLine, bottomLine
			@visible = (=>
				result = []
				vt = @scrollTop + @maxHead
				for num, line of @lines
					num -= 0

					posTop    = (@start + num + 1) * @lineSize
					posBottom = posTop + @lineSize

					if vt - @lineSize <= posTop and posBottom <= @scrollBottom
						result.push line

				return result
			)()

			if vnode.attrs.onvisible
				vnode.attrs.onvisible @visible

			m.redraw()

		view: (vnode) ->
			m "div.table-root", { 
				onscroll: (event) =>
					await @scroll vnode, event
				oncreate: (event) =>
					load = =>
						await @scroll vnode, { target: event.dom }
						m.redraw()

					bus.on "load",   load
					bus.on "resize", load
			},
				if @lines
					m "div.table", { style: height: (@count * @lineSize) + "px" },
						m "table", { style: top: (@start * @lineSize) + "px" }, [
							m "thead", [
								m "tr", language.headers.map (header) =>
									m "th", { 
										style: top: (@scrollTop - (@start * @lineSize)) + "px"
										oncreate: (vnode) =>
											setTimeout =>
												head = vnode.dom.clientHeight
												if head > @maxHead
													@maxHead = head
											, 150

									}, header
							]
							m "tbody", [
								@lines.map (line, i) =>
									m "tr", { 
										class: "light" if @light == i
									}, line.map (cell) =>
										m "td", cell
							]
						]

module.exports = Table
