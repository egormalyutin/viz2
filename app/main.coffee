require "babel-polyfill"

# todo: update
# todo: headers
# todo: canvasjs and go to line by click

WS = require "./ws"

parseCSV = (text) ->
	return text
		.split "\n"
		.map (str) -> str.split ";"

CHUNK_SIZE = 100

do ->
	# Connect to WebSocket server
	ws = await new WS config.ws

	# Aliases
	$  = (args...) -> document.querySelector    args...
	$$ = (args...) -> document.querySelectorAll args...
	c$ = (args...) -> document.createElement    args...

	# get root element
	root = $ "#table-root"
	pad  = $ "#table-pad"
	# root = pad
	# root = $ "#table-root"

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
	lastCount = 0
	count = 0

	# error handler
	ws.on "error", (err) ->
		console.error err

	# visible rows
	visible = []
	visibleElements = []

	topChunk = null
	chunks =
		top: null
		middle: null
		bottom: null

	allLines = []

	updater = null


	updateCount = (n) ->
		lastCount = count
		count = n

		# newLines = parseCSV await ws.get "get",
			# start: lastCount
			# end:   count - 1

		# console.log "New lines:", newLines

		isBottomChunk = topChunk + 1 >= Math.floor count / CHUNK_SIZE
		if isBottomChunk
			updater true

			# ls = parseCSV await ws.get "get", start: lastCount, end: count

			# chunks.middle = []
			# chunks.middle.push ls...


			# # console.log newLines
			# # allLines.push newLines
			# # if newLines.length + chunks.middle.length > 100
			# # 	chunks.middle ?= []
			# # 	chunks.bottom = []
			# # 	chunks.middle.push newLines[100 - chunks.middle.length]...
			# # 	chunks.bottom.push newLines[100 - chunks.middle.length..]...

			# for row in ls 
			# 	tr = c$ "tr"
			# 	for col in row
			# 		td = c$ "td"
			# 		td.innerText = col
			# 		tr.appendChild td
			# 	table.appendChild tr

		# if topChunk >= Math.floor count / CHUNK_SIZE
		# 	allLines.push newLines...
		# 	chunks.middle.push newLines...
		# 	for row in newLines
		# 		tr = c$ "tr"
		# 		for col in row
		# 			td = c$ "td"
		# 			td.innerText = col
		# 			tr.appendChild td
		# 		table.appendChild tr

	# start vizualizer

	lastBt = false
	updateThs = ->

	startViz = ->
		update = updater = (force) ->
			isBottomChunk = topChunk + 1 >= Math.floor count / CHUNK_SIZE

			# if isBottomChunk
			# 	allLines = []
			# 	chunk = await ws.get "get", start: lastCount, end: count
			# 	allLines.push chunk...
			# 	for row in chunk
			# 		tr = c$ "tr"
			# 		for col in row
			# 			td = c$ "td"
			# 			td.innerText = col
			# 			tr.appendChild td
			# 		table.appendChild tr
			# 	chunks.middle = chunk
			# 	return

			scroll = pad.scrollTop
			topLine = Math.floor scroll / trHeight
			nTopChunk = Math.floor topLine / CHUNK_SIZE
			return if not force and topChunk is nTopChunk

			allLines = []
			lastChunk = topChunk	
			topChunk = nTopChunk

			if (lastBt and not isBottomChunk) or force
				#
			else if topChunk is lastChunk - 1 or 
				chunks.top = chunks.middle 
			else if topChunk - 1 >= 0
				chunks.top = parseCSV await ws.get "get", 
					start: (topChunk - 1) * CHUNK_SIZE
					end:   topChunk * CHUNK_SIZE
			else
				chunks.top = null

			lastBt = isBottomChunk

			chunks.middle = parseCSV await ws.get "get",
				start: topChunk * CHUNK_SIZE
				end:   Math.min(count - 1, (topChunk + 1) * CHUNK_SIZE)

			if topChunk is lastChunk + 1
				chunks.bottom = chunks.middle 
			if topChunk + 1 <= Math.floor(count / CHUNK_SIZE)
				chunks.bottom = parseCSV await ws.get "get", 
					start: (topChunk + 1) * CHUNK_SIZE
					end:   Math.min(count - 1, (topChunk + 2) * CHUNK_SIZE)
			else
				chunks.bottom = null

			table.innerHTML = ""

			if chunks.top
				topOffset = -1	
			else
				topOffset = 0

			ths = []

			thead = c$ "thead"
			table.appendChild thead

			thTr = c$ "tr"
			thead.appendChild thTr

			for name in config.languages[0].headers
				th = c$ "th"
				th.innerText = name 
				ths.push th
				thTr.appendChild th

			tbody = c$ "tbody"
			table.appendChild tbody

			render = (chunk) ->
				allLines.push chunk...
				for row in chunk
					tr = c$ "tr"
					for col in row
						td = c$ "td"
						td.innerText = col
						tr.appendChild td
					tbody.appendChild tr

			updateThs = ->
				# th.style.top = (window.scrollY - ((window.scrollY / trHeight + 20) * trHeight)) + "px"
				# if chunks.top
				# 	offset = (topChunk - 1) * CHUNK_SIZE * trHeight
				# else
				# 	offset = topChunk * CHUNK_SIZE * trHeight

				# for th in ths
				# 	th.style.top = pad.scrollTop - offset + "px"

				# console.log offset
				# console.log ths[0].offsetTop
				# l = pad.scrollTop - ((topChunk + topOffset) * CHUNK_SIZE * trHeight)
				# for th in ths
					# th.style.top = l + "px"

			if chunks.top
				render chunks.top
				table.style.top = (topChunk - 1) * CHUNK_SIZE * trHeight + "px"
			else
				table.style.top = topChunk * CHUNK_SIZE * trHeight + "px"

			render chunks.middle

			if chunks.bottom
				render chunks.bottom

		topElement = null
		bottomElement = null

		findVisible = ->
			topLine = Math.floor scroll / trHeight
			bottomLine = Math.ceil (scroll + pad.offsetHeight) / trHeight

			top = topLine - topChunk * CHUNK_SIZE
			if chunks.top
				top += CHUNK_SIZE

			bottom = bottomLine - 1 - topChunk * CHUNK_SIZE
			if chunks.top
				bottom += CHUNK_SIZE

			# topElement?.style.background = "initial"
			# topElement = table.children[top]
			# topElement?.style.background = "blue"

			# bottomElement?.style.background = "initial"
			# bottomElement = table.children[bottom] ? table.children[table.children.length - 1]
			# bottomElement?.style.background = "blue"

			visible = allLines[top .. Math.min(allLines.length - 1, bottom)]
			visibleElements = ([].concat table.children)[top .. Math.min(allLines.length - 1, bottom)]

		update()
		findVisible()

		scroll = pad.scrollTop
		# thsScroll = pad.scrollTop

		pad.addEventListener "scroll", ->
			updateThs()
			setTimeout updateThs, 10
			setTimeout updateThs, 20
			setTimeout updateThs, 30
			setTimeout updateThs, 50
			setTimeout updateThs, 100

		setInterval ->
			if pad.scrollTop isnt scroll
				scroll = pad.scrollTop
				update()
				updateThs()
				findVisible()
		, 50
		setInterval ->
			await update()
			await findVisible()
		, 200

	# get initial count of lines
	c = await ws.get "lines"
	count = c
	console.log "Lines count:", c
	startViz()
	root.style.height = count * trHeight + "px"

	ws.on "lines", (c) ->
		updateCount c
		console.log "Lines count:", c
		# update pad height
		root.style.height = count * trHeight + "px"
