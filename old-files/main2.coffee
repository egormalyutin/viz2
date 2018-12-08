require "babel-polyfill"

WS = {}

parseCSV = (text) ->
	return text
		.split "\n"
		.map (str) -> str.split ";"

do ->
	# Connect to WebSocket server
	ws = await new WS config.ws

	# Aliases
	$  = (args...) -> document.querySelector    args...
	$$ = (args...) -> document.querySelectorAll args...
	c$ = (args...) -> document.createElement    args...

	# get root element
	root = $ "#root"

	# <tr> height
	trHeight = do ->
		table = c$ "table"
		tr = c$ "tr"
		td = c$ "td"
		td.innerText = "123ABCabc"

		tr.appendChild td
		table.appendChild tr
		root.appendChild table

		height = tr.offsetHeight

		root.removeChild table
		
		return height

	# debug logs
	console.log "Config:", config
	console.log "Root:", root
	console.log "<tr> height:", trHeight

	# initialize pads
	table = c$ "table"
	table.className = "table"
	root.appendChild table

	# line count
	count = 0

	# error handler
	ws.on "error", (err) ->
		console.error err

	updateTh = ->

	# render given rows
	renderRows = (rows, top) ->
		table.innerHTML = ""

		thTr = c$ "tr"

		ths = []

		for name in ["uasdhas"]
			th = c$ "th"
			th.innerText = name 
			thTr.appendChild th
			updateTh = ->
				th.style.top = (window.scrollY - ((window.scrollY / trHeight + 20) * trHeight)) + "px"
			updateTh()

		table.appendChild thTr

		for row in rows
			tr = c$ "tr"

			for col in row
				td = c$ "td"
				td.innerText = col
				tr.appendChild td

			table.appendChild tr

	# visible rows
	visible = []

	# start vizualizer
	startViz = ->
		update = ->
			# calculate top line
			top    = Math.floor window.scrollY / trHeight
			bottom = Math.ceil (window.scrollY + window.innerHeight) / trHeight

			topDiff = 20
			top -= topDiff
			if top < 0
				topDiff += top
				top = 0

			bottomDiff = 20
			bottom += bottomDiff
			if bottom >= count
				bottomDiff -= bottom - count
				bottom = count

			rows = parseCSV await ws.get "get", { start: top, end: bottom }
			renderRows rows, top

			table.style.top = top * trHeight + "px"

		update 0

		scroll = window.scrollY
		setInterval ->
			if window.scrollY isnt scroll
				scroll = window.scrollY
				update()
		, 50 


	# get initial count of lines
	ws.send "lines"
	ws.on "lines", (c) ->
		count = c
		console.log "Lines count:", c
		startViz()

		# update pad height
		root.style.height = count * trHeight + "px"
		
# require "babel-polyfill"

# # todo: update
# # todo: headers

# WS = require "./ws"

# parseCSV = (text) ->
# 	return text
# 		.split "\n"
# 		.map (str) -> str.split ";"

# CHUNK_SIZE = 100

# do ->
# 	# Connect to WebSocket server
# 	ws = await new WS config.ws

# 	# Aliases
# 	$  = (args...) -> document.querySelector    args...
# 	$$ = (args...) -> document.querySelectorAll args...
# 	c$ = (args...) -> document.createElement    args...

# 	# get root element
# 	pad  = $ "#table-pad"
# 	root = $ "#table-root"

# 	# <tr> height
# 	trHeight = do ->
# 		table = c$ "table"
# 		tr = c$ "tr"
# 		td = c$ "td"
# 		td.innerText = "123ABCabc"

# 		tr.appendChild td
# 		table.appendChild tr
# 		root.appendChild table

# 		height = tr.offsetHeight

# 		root.removeChild table
		
# 		return height

# 	# debug logs
# 	console.log "Config:", config
# 	console.log "Root:", root
# 	console.log "<tr> height:", trHeight

# 	# initialize pads
# 	table = c$ "table"
# 	table.className = "table"
# 	root.appendChild table

# 	# line count
# 	lastCount = 0
# 	count = 0

# 	# error handler
# 	ws.on "error", (err) ->
# 		console.error err

# 	# visible rows
# 	visible = []
# 	visibleElements = []

# 	topChunk = null
# 	chunks =
# 		top: null
# 		middle: null
# 		bottom: null

# 	allLines = []


# 	updateCount = (n) ->
# 		lastCount = count
# 		count = n

# 		newLines = parseCSV await ws.get "get",
# 			start: lastCount
# 			end:   count - 1

# 		console.log "New lines:", newLines

# 		allLines.push newLines...
# 		chunks.middle.push newLines...
# 		for row in newLines
# 			tr = c$ "tr"
# 			for col in row
# 				td = c$ "td"
# 				td.innerText = col
# 				tr.appendChild td
# 			table.appendChild tr

# 	# start vizualizer
# 	startViz = ->
# 		update = (force) ->
# 			scroll = pad.scrollTop
# 			topLine = Math.floor scroll / trHeight
# 			nTopChunk = Math.floor topLine / CHUNK_SIZE
# 			return if not force and topChunk is nTopChunk

# 			allLines = []
# 			lastChunk = topChunk	
# 			topChunk = nTopChunk

# 			if topChunk is lastChunk - 1
# 				chunks.top = chunks.middle 
# 			else if topChunk - 1 >= 0
# 				chunks.top = parseCSV await ws.get "get", 
# 					start: (topChunk - 1) * CHUNK_SIZE
# 					end:   topChunk * CHUNK_SIZE
# 			else
# 				chunks.top = null

# 			chunks.middle = parseCSV await ws.get "get",
# 				start: topChunk * CHUNK_SIZE
# 				end:   Math.min(count - 1, (topChunk + 1) * CHUNK_SIZE)

# 			if topChunk is lastChunk + 1
# 				chunks.bottom = chunks.middle 
# 			if topChunk + 1 <= Math.floor(count / CHUNK_SIZE)
# 				chunks.bottom = parseCSV await ws.get "get", 
# 					start: (topChunk + 1) * CHUNK_SIZE
# 					end:   Math.min(count - 1, (topChunk + 2) * CHUNK_SIZE)
# 			else
# 				chunks.bottom = null

# 			table.innerHTML = ""

# 			render = (chunk) ->
# 				allLines.push chunk...
# 				for row in chunk
# 					tr = c$ "tr"
# 					for col in row
# 						td = c$ "td"
# 						td.innerText = col
# 						tr.appendChild td
# 					table.appendChild tr

# 			if chunks.top
# 				render chunks.top
# 				table.style.top = (topChunk - 1) * CHUNK_SIZE * trHeight + "px"
# 			else
# 				table.style.top = topChunk * CHUNK_SIZE * trHeight + "px"

# 			render chunks.middle

# 			if chunks.bottom
# 				render chunks.bottom

# 		topElement = null
# 		bottomElement = null

# 		findVisible = ->
# 			topLine = Math.floor scroll / trHeight
# 			bottomLine = Math.ceil (scroll + pad.offsetHeight) / trHeight

# 			top = topLine - topChunk * CHUNK_SIZE
# 			if chunks.top
# 				top += CHUNK_SIZE

# 			bottom = bottomLine - 1 - topChunk * CHUNK_SIZE
# 			if chunks.top
# 				bottom += CHUNK_SIZE

# 			# topElement?.style.background = "initial"
# 			# topElement = table.children[top]
# 			# topElement?.style.background = "blue"

# 			# bottomElement?.style.background = "initial"
# 			# bottomElement = table.children[bottom] ? table.children[table.children.length - 1]
# 			# bottomElement?.style.background = "blue"

# 			visible = allLines[top .. Math.min(allLines.length - 1, bottom)]
# 			visibleElements = ([].concat table.children)[top .. Math.min(allLines.length - 1, bottom)]

# 		update()
# 		findVisible()

# 		scroll = pad.scrollTop
# 		setInterval ->
# 			if pad.scrollTop isnt scroll
# 				scroll = pad.scrollTop
# 				update()
# 				findVisible()
# 		, 50
# 		setInterval ->
# 			await update()
# 			await findVisible()
# 		, 200

# 	# get initial count of lines
# 	c = await ws.get "lines"
# 	count = c
# 	console.log "Lines count:", c
# 	startViz()
# 	root.style.height = count * trHeight + "px"

# 	ws.on "lines", (c) ->
# 		updateCount c
# 		console.log "Lines count:", c
# 		# update pad height
# 		root.style.height = count * trHeight + "px"

