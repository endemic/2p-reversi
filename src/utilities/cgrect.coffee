###
My lolbears interpretation of CGRect in CoffeeScript
TODO: This should probably just be rewritten to support collision detection of jQuery elements
###
define () ->
	CGRect =
		intersectsRect: (a, b) ->
			# Assumes an origin of upper left
			if Math.abs((a.x + a.width / 2) - (b.x + b.width / 2)) < (a.width / 2 + b.width / 2) and Math.abs((a.y - a.height / 2) - (b.y - b.height / 2)) < (a.height / 2 + b.height / 2)
				return true
			else
				return false

		make: (x, y, width, height) ->
			return { x: x, y: y, width: width, height: height }