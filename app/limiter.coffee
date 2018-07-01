m = require "mithril"
bus = require "./bus"

class Limiter
	bind: (vnode, dom) ->
		first  = vnode.attrs.first.dom
		second = vnode.attrs.second.dom

		@state = 0.5

		window.onresize = =>
			bus.emit "resize"
			ch = document.documentElement.clientHeight
			first.style.height  = @state * ch + "px"
			second.style.height = (1 - @state) * ch + "px"

		dom.onmousedown = (e) =>
			first.children[0].style.overflowY  = "hidden"
			second.children[0].style.overflowY = "hidden"

			shiftY = do ->
				box = dom.getBoundingClientRect()
				top = box.top + window.pageYOffset
				return e.pageY - top

			document.onmousemove = (e) =>
				ch = document.documentElement.clientHeight

				top = 0
				bottom = ch - dom.clientHeight

				tr = e.pageY - shiftY

				return if e.pageY < top or e.pageY > bottom

				first.style.height  = tr + "px"
				second.style.height = ch - tr + "px"

				@state = tr / ch

				bus.emit "resize"

				if tr < 100
					console.log "hide first"
				else if tr > bottom - 100
					console.log "hide second"

			document.onmouseup = (e) =>
				document.onmousemove = document.onmouseup = null

				first.children[0].style.overflowY  = "auto"
				second.children[0].style.overflowY = "auto"

		dom.ondragstart = => false

	view: (vnode) ->
		m "div.limiter", {
			oncreate: (e) => @bind vnode, e.dom
		},
			m "div.limiter-line"

module.exports = Limiter
