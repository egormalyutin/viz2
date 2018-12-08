bus = new (require "events")

window.onload = ->
	bus.emit "load"
	bus.emit "resize"

	setTimeout ->
		bus.emit "resize"
	, 1000

	setTimeout ->
		bus.emit "resize"
	, 2000

	window.addEventListener "resize", ->
		bus.emit "resize"

module.exports = bus
