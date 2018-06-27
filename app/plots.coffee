Chart = require "chart.js"
m = require "mithril"

{ language } = require "./languages"

# todo: throttle

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
						stacked: true,
						gridLines: {
							display: true,
							color: "rgba(255,99,132,0.2)"
						}
					}],
					xAxes: [{
						# display: false
						gridLines: {
							display: false
						}
					}]
				}
			}
		}

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

		@chart.update()

	view: (vnode) ->
		m "div.chart-container",
			m "canvas.plot", {
				oncreate: (ctx) =>
					@bindChart vnode, ctx.dom
			}

class Plots
	view: (vnode) ->
		dateId = config.format.indexOf "date"
		m "div.plots", config.plots.map (plot, i) ->
			m Plot, {
				name: language.plots[i]
				data: plot.data.map (i) ->
					return {
						name: language.headers[i]
						color: language.colors i
						data: vnode.attrs.lines.map (line) ->
							return line.filter (cell, j) ->
								return i == j
					}

				labels: vnode.attrs.lines.map (line) ->
					return line[dateId].split(" ")[1]
			}

module.exports = Plots
