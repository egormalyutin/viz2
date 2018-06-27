m = require "mithril"

{ language } = require "./languages"

papa = require "papaparse"

class Table
		constructor: ->
			@count   = 0
			@start   = 0
			@maxHead = 0
			@lines   = []
			@visible = []

		oninit: (vnode) ->
			@lineSize = await new Promise (resolve) ->
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

			@count = await @loadLinesCount(vnode)
			console.log "Lines count:", @count
			m.redraw()

		loadLines: (vnode, start, end) ->
			return new Promise (resolve) =>
				vnode.attrs.ws.get("get", { start, end }).then (lines) =>
					{ data } = papa.parse lines
					resolve data

		loadLinesCount: (vnode) ->
			return new Promise (resolve) =>
				vnode.attrs.ws.get("lines").then (lines) =>
					resolve lines

		scroll: (vnode, event) ->
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
					await @scroll vnode,  event
				oncreate: (event) =>
					@updateInterval = setInterval =>
						await @scroll vnode, { target: event.dom }
						m.redraw()
					, 500
				onremove: (vnode) =>
					clearInterval @updateInterval
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
								@lines.map (line) =>
									m "tr", line.map (cell) =>
										m "td", cell
							]
						]

module.exports = Table
