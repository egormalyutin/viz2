Chart = require "chart.js"
m = require "mithril"

{ language } = require "./languages"
{ debounce } = require "./util"

class Plot
	constructor: ->
		@chart = null

	bindChart: (vnode, ctx) ->
		@chart = new Chart ctx, {
			type: 'line',
			data: {
				labels: vnode.attrs.labels,
				datasets: vnode.attrs.data.map (data) ->
					return {
						label: data.name
						borderColor: data.color
						backgroundColor: data.color
						data: data.data,
						fill: false
					}
			},
			options: {
				animation: false
				responsive: true,
				elements:
					{
						point: {
							radius: if vnode.attrs.mode == "range" then 0 else 3
						}
					}
				title: {
					display: true,
					text: vnode.attrs.name
				},
				hover: {
					mode: 'nearest',
					intersect: true
				},
				maintainAspectRatio: false,
				scales: {
					yAxes: [{
						gridLines: {
							display: true,
							color: "rgba(89, 98, 117, 0.2)"
						}
					}],
					xAxes: [{
						gridLines: {
							display: true,
							color: "rgba(89, 98, 117, 0.2)"
						}
					}]
				}

				onClick: (event) =>
					elem = @chart.getElementsAtEvent(event)[0]
					return unless elem
					i = elem._index
					vnode.attrs.onclick i
			}
		}

		@update = debounce =>
			@chart.update {
				duration: 0
				lazy: false
			}
			vnode.attrs.finished()
		, 20

	onbeforeupdate: (vnode) ->
		@chart.data.datasets = vnode.attrs.data.map (data) ->
			return {
				label: data.name
				backgroundColor: data.color
				borderColor: data.color
				data: data.data,
				fill: false
			}

		@chart.data.labels = vnode.attrs.labels
		@chart.options.title.text = vnode.attrs.name
		@chart.options.elements.point.radius = if vnode.attrs.mode == "range" then 0 else 3

		@update()

	view: (vnode) ->
		m "div.chart-container",
			m "canvas.plot", {
				oncreate: (ctx) =>
					@bindChart vnode, ctx.dom
			}

class Plots
	oninit: ->
		@count = config.plots.length

	view: (vnode) ->
		dateId = config.format.indexOf "date"

		if vnode.attrs.updateCount
			@count = config.plots.length

		m "div.plots", [
			plots = config.plots.map (plot, i) =>
				return m Plot, {
					name: language.plots[i]
					mode: vnode.attrs.mode
					data: plot.data.map (i) =>
						return {
							name: language.headers[i]
							color: language.colors(i)
							data: vnode.attrs.lines.map (line) ->
								return line.filter (cell, j) ->
									return i == j
								.map (cell) ->
									return parseFloat cell
						}

					labels: vnode.attrs.lines.map (line) =>
						return line[dateId].split(" ")[1]

					onclick: vnode.attrs.onclick or (=>)

					finished: => @count--
				}

			if vnode.attrs.loading or @count > 0
				m "div.preloader-box", 
					m "div.preloader"
		]

module.exports = Plots
