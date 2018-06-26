EventEmitter = require "events"

class WS extends EventEmitter
	constructor: (@address) ->
		super()
		return new Promise (resolve, reject) =>
			@ws = new WebSocket @address

			@ws.onopen = =>
				console.log "Connection open on " + @address
				resolve @

			@ws.onclose = =>
				console.log "Connection closed"

			@ws.onerror = (err) =>
				reject err

			@ws.onmessage = (event) =>
				data = JSON.parse event.data

				unless data.type?
					throw new Error "Invalid message: no \"type\" field:", event

				unless data.data?
					throw new Error "Invalid message: no \"data\" field: ", event

				@emit data.type, JSON.parse(data.data)

	receive: (type) ->
		return new Promise (resolve) =>
			@once type, resolve

	get: (type, data) ->
		@send type, data 
		return await @receive(type)

	send: (type, data) ->
		@ws.send JSON.stringify { type, data: JSON.stringify(data) }

module.exports = WS
