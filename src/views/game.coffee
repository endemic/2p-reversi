###
@description Gameplay view
###
define [
	'jquery'
	'backbone'
	'cs!utilities/environment'
	'cs!views/common/scene'
	'cs!views/common/modal'
	'text!templates/game.html'
], ($, Backbone, Env, Scene, Modal, template) ->
	class GameScene extends Scene
		events: ->
			# Determine whether touchscreen or desktop
			if Env.mobile
				events = 
					'touchstart .new': 'reset'
					'touchstart .back': 'back'
					'touchstart .board > div': 'move'
			else
				events = 
					'click .new': 'reset'
					'click .back': 'back'
					'click .board > div': 'move'

		initialize: ->
			@elem = $(template)

			# Instantiate a reusable modal, and attach it to this scene
			@modal = new Modal { el: @elem }

			# Listen for sfx events from the modal
			@modal.on 'sfx:play', (id) => 
				@trigger 'sfx:play', id

			# Reference for the game board
			@board = $('.board', @elem)

			@turns = 0

			@render()

		back: (e) ->
			e.preventDefault()

			# Don't allow button to be activated more than once
			@undelegateEvents()
			
			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', 'title'

		###
		@description Place a piece
		###
		move: (e) ->
			# Where we append the piece
			square = $(e.target)

			# Only allow one piece per spot on the game board
			if square.children('.piece').length > 0 then return

			# Don't allow nested piece placement
			if not square.data('index') then return

			# Find the index of the current piece
			index = parseInt square.data('index'), 10

			# Simple validation
			captured = @validate index, @currentPlayer

			if captured is false
				console.log 'Invalid move!'
				@trigger 'vfx:play', 'shake'
				return

			# Otherwise, place the piece and flip captured pieces

			# Complicated HTML to allow each piece to have a white + black side
			piece = $('<div class="piece"><div class="white"></div><div class="black"></div>').data('color', 'white')

			square.append piece

			# Flip to black if necessary - TODO: use "animate" so vendor prefixes are automatically added
			if @currentPlayer is 'black' then piece.css({ '-webkit-transform': 'rotateY(180deg)' }).data('color', 'black')

			# Flip captured pieces
			captured.forEach (group, i) =>
				if group.length != undefined
					group.forEach (pieceIndex, j) =>
						piece = @board.children('div').eq(pieceIndex).children('.piece')
						# Determine when to rotate to 180deg (black) and when to rotate to 0deg (white)
						if piece.data('color') is 'white'
							piece.animate { '-webkit-transform': 'rotateY(180deg)' }, 250, 'ease-in-out'
						else
							piece.animate { '-webkit-transform': 'rotateY(0deg)' }, 250, 'ease-in-out'
						# Set the new color
						piece.data 'color', @currentPlayer

			# Swap turn
			if @currentPlayer is "black" then @currentPlayer = "white" else @currentPlayer = "black"

			@turns += 1

		checkWinCondition: ->
			console.log "Winning!"

		###
		Valid moves must be next to at least one piece of the opposite color in one of 8 directions;
			in one of those 8 directions, there must be another piece of the same color after the first piece
		###
		validate: (index, color) ->
			# Validation for first 4 moves just ensures they're at the center of the board
			if @turns < 4 and [27, 28, 35, 36].indexOf(index) == -1
				return false
			else if @turns < 4 and [27, 28, 35, 36].indexOf(index) != -1
				return []

			# Call our eight (TODO) validation methods
			left = @validateLeft index, color
			up = @validateUp index, color
			right = @validateRight index, color

			# Note: Validation around the edge of the board isn't working correctly
			bottom = @validateBottom index, color

			upLeft = @validateUpperLeft index, color

			console.log [ left, upLeft, up, right, bottom ]

			if not left and not upLeft and not up and not right and not bottom
				return false
			else
				return [ left, upLeft, up, right, bottom ]

		###
		@description One of eight validation methods; checks to the left of a potentially placed piece
		@param {Number} index The board index of the (potentially) new piece
		@param {String} color The color of the (potentially) new piece
		###
		validateLeft: (index, color) ->
			squares = @board.children('div')
			leftBorder = Math.floor(index / 8) * 8

			# If too close to the left border of the board, automatically return false
			if index - 1 <= leftBorder then return false

			piece = squares.eq(index - 1).children('.piece')
			# Check to see if the first square to the left exists, and is a different color
			if piece.length == 0 or piece.data('color') == color then return false

			# Now, search for a piece of the same color
			i = index - 2
			j = leftBorder
			captured = [index - 1]

			while i > j
				piece = squares.eq(i).children('.piece')
				
				# If we hit an empty space before a same-color piece, nothing is valid in that direction
				if piece.length is 0 then return false

				# For a successful move, we have to encounter another piece of the same color
				if piece.data('color') is color then i = j else captured.push i

				i -= 1

			# If the "captured" array includes the last square, that means there were no opposite-colored pieces
			if captured.indexOf(j) != -1 then return false

			# Finally, we have a valid move, and are returning an array of square indices that contain "captured" pieces
			return captured

		###
		@description One of eight validation methods; checks to the right of a potentially placed piece
		@param {Number} index The board index of the (potentially) new piece
		@param {String} color The color of the (potentially) new piece
		###
		validateRight: (index, color) ->
			squares = @board.children('div')
			rightBorder = Math.floor(index / 8) * 8 + 7

			# If too close to the right border of the board, automatically return false
			if index + 1 >= rightBorder then return false

			piece = squares.eq(index + 1).children('.piece')
			# Check to see if the first square to the right exists, and is a different color
			if piece.length == 0 or piece.data('color') == color then return false

			# Now, search for a piece of the same color
			i = index + 2
			j = rightBorder
			captured = [index + 1]

			while i < j
				piece = squares.eq(i).children('.piece')
				
				# If we hit an empty space before a same-color piece, nothing is valid in that direction
				if piece.length is 0 then return false

				# For a successful move, we have to encounter another piece of the same color
				if piece.data('color') is color then i = j else captured.push i

				i += 1

			# If the "captured" array includes the last square, that means there were no opposite-colored pieces
			if captured.indexOf(j) != -1 then return false

			# Finally, we have a valid move, and are returning an array of square indices that contain "captured" pieces
			return captured

		###
		@description One of eight validation methods; checks to the top of a potentially placed piece
		@param {Number} index The board index of the (potentially) new piece
		@param {String} color The color of the (potentially) new piece
		###
		validateUp: (index, color) ->
			squares = @board.children('div')
			# If too close to the top of the board, automatically return false
			if index - 8 <= 0 then return false

			piece = squares.eq(index - 8).children('.piece')
			# Check to see if the first square to the top exists, and is a different color
			if piece.length == 0 or piece.data('color') == color then return false

			# Now, search for a piece of the same color
			i = index - 16
			j = 0
			captured = [index - 8]

			while i > j
				piece = squares.eq(i).children('.piece')
				
				# If we hit an empty space before a same-color piece, nothing is valid in that direction
				if piece.length is 0 then return false

				# For a successful move, we have to encounter another piece of the same color
				if piece.data('color') is color then i = j else captured.push i

				i -= 8

			# If the "captured" array includes the last square, that means there were no opposite-colored pieces
			if captured.indexOf(j) != -1 then return false

			# Finally, we have a valid move, and are returning an array of square indices that contain "captured" pieces
			return captured

		###
		@description One of eight validation methods; checks to the bottom of a potentially placed piece
		@param {Number} index The board index of the (potentially) new piece
		@param {String} color The color of the (potentially) new piece
		###
		validateBottom: (index, color) ->
			squares = @board.children('div')
			bottomBorder = 63 - index % 8

			# If too close to the bottom border of the board, automatically return false
			if index + 8 >= bottomBorder then return false

			piece = squares.eq(index + 8).children('.piece')
			# Check to see if the first square to the bottom exists, and is a different color
			if piece.length == 0 or piece.data('color') == color then return false

			# Now, search for a piece of the same color
			i = index + 16
			j = bottomBorder
			captured = [index + 8]

			while i < j
				piece = squares.eq(i).children('.piece')
				
				# If we hit an empty space before a same-color piece, nothing is valid in that direction
				if piece.length is 0 then return false

				# For a successful move, we have to encounter another piece of the same color
				if piece.data('color') is color then i = j else captured.push i

				i += 8

			# If the "captured" array includes the last square, that means there were no opposite-colored pieces
			if captured.indexOf(j) != -1 then return false

			# Finally, we have a valid move, and are returning an array of square indices that contain "captured" pieces
			return captured

		###
		@description One of eight validation methods; checks to the uppper left of a potentially placed piece
		@param {Number} index The board index of the (potentially) new piece
		@param {String} color The color of the (potentially) new piece
		###
		validateUpperLeft: (index, color) ->
			squares = @board.children('div')
			leftBorder = Math.floor(index / 8) * 8

			# If too close to the left border of the board, automatically return false
			if index - 1 <= leftBorder or index - 9 <= 0 then return false

			piece = squares.eq(index - 9).children('.piece')
			# Check to see if the first square to the bottom exists, and is a different color
			if piece.length == 0 or piece.data('color') == color then return false

			# Now, search for a piece of the same color
			i = index - 18
			# Determine upper-left most piece from the index
			# e.g. index at 35, border at 32
			# j = 35 - (35 - 32) - (35 - 32) * 8
			# j = 35 - 3 - 24 = 8
			j = index - (index - leftBorder) - (index - leftBorder) * 8
			captured = [index - 9]

			while i > j
				piece = squares.eq(i).children('.piece')
				
				# If we hit an empty space before a same-color piece, nothing is valid in that direction
				if piece.length is 0 then return false

				# For a successful move, we have to encounter another piece of the same color
				if piece.data('color') is color then i = j else captured.push i

				i -= 9

			# If the "captured" array includes the last square, that means there were no opposite-colored pieces
			if captured.indexOf(j) != -1 then return false

			# Finally, we have a valid move, and are returning an array of square indices that contain "captured" pieces
			return captured

		###
		@description Remove existing pieces, and reset the game
		###
		reset: ->
			@elem.find('.piece').remove()
			@turns = 0

		resize: (width, height, orientation) ->
			# Use Math.floor here to ensure the grid doesn't round up to be larger than width/height of container
			if orientation is 'landscape'
				width = Math.round(height * 0.95 / 8) * 8 	# Make sure grid background size is 95% of viewport and an even multiple of 8
				@board.width width
				@board.height width

				# Add some margin to the board, so it appears centered
				margin = (height - width) / 2
				@board.css
					'margin': "#{margin}px 0"

			else if orientation is 'portrait'
				width = Math.round(width * 0.95 / 8) * 8	# grid size is 95% of viewport and an even multiple of 8
				@board.width width
				@board.height width

				# Add some margin to the board, so it appears centered
				margin = (width - height) / 2
				@board.css
					'margin': "0 #{margin}px"

		show: (duration = 500, callback) ->
			super duration, callback

			@currentPlayer = "black"

			# Add an "index" value to each board square
			@board.children('div').each (i, element)->
				$(element).data 'index', i

			# Remove existing pieces
			@elem.find('.piece').remove()

			# Read previous game moves

			# Re-create the current game state