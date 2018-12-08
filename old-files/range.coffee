m = require "mithril"
slider = require "nouislider"

# todo: resize

class Range
	view: (vnode) ->
		lines = vnode.attrs.lines

		m "div.range", m "div.range-input", {
			oncreate: ({dom}) =>
				limit = 5000
				s = slider.create dom, {
					start: [0, limit]
					step: 1
					limit: limit
					behaviour: 'drag'
					connect: true
					range: {
						min: 0
						max: lines 
					}
				}

				s.on "change", (values) ->
					start = parseFloat values[0]
					end   = parseFloat values[1]
					vnode.attrs.onchange start, end
		}

module.exports = Range
