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
					'touchend .quit': 'quit'
					'touchend .board > div': 'move'
			else
				events = 
					'click .quit': 'quit'
					'click .board > div': 'move'

		# Used for Game Center matches
		@matchId: null

		initialize: ->
			@elem = $(template)

			# Instantiate a reusable modal, and attach it to this scene
			@modal = new Modal { el: @elem }

			# Listen for sfx events from the modal
			@modal.on 'sfx:play', (id) => 
				@trigger 'sfx:play', id

			# Reference for the game board
			@board = $('.board', @elem)

			# Change text in "quit" button if playing a multiplayer game
			if @matchId != null then @$('.button.quit span').html 'Options'

			@turns = 0

			@render()

		quit: (e) ->
			e.preventDefault()
			@trigger 'sfx:play', 'button'

			if @matchId is null
				@modal.show
					'title': 'Are you sure?'
					'buttons': [
						{
							'text': 'Yes, quit'
							'callback': =>
								@trigger 'scene:change', 'title'
						}, {
							'text': 'No, play'
						}
					]
			else
				@modal.show
					'title': 'Options'
					'buttons': [
						{
							'text': 'Back'
							'callback': =>
								@trigger 'scene:change', 'gamecenter'
						}, {
							'text': 'Play'
						}
					]

		###
		@description Place a piece
		###
		move: (e) ->

			# Handle Game Center matches -- only allow active player to play
			if GameCenter? and GameCenter.matches[@matchId].currentParticipant.playerId != window.GameCenter.authenticatedPlayer.playerId
				@board.addClass 'shake'
				_.delay =>
					@board.removeClass 'shake'
				, 500

				return

			# Where we append the piece
			square = $(e.target)

			# Don't allow nested piece placement
			# if not square.data('index') then return
			if square.hasClass('square') is false then square = square.parents('.square')

			# Only allow one piece per spot on the game board
			if square.children('.piece').length > 0 then return

			# Find the index of the current piece
			index = parseInt square.data('index'), 10

			# Simple validation
			captured = @validate index, @currentPlayer

			if captured is false
				# @trigger 'vfx:play', 'shake'
				@trigger 'sfx:play', 'error'
				@incorrect += 1

				# Show a hint if the player tries to play in a bad spot more than 2 times
				if @incorrect > 1
					validMoves = @canPlay @currentPlayer

					# Show a hint
					children = @board.children('div')
					validMoves.forEach (square) =>
						children.eq(square).children('.hint').show()

				@board.addClass 'shake'
				_.delay =>
					@board.removeClass 'shake'
				, 500
				
				return

			# Remove the hint in the square the user is playing on
			square.children('.hint').remove()

			# Hide other hints if move was successful
			$('.hint').hide()

			@trigger 'sfx:play', 'move'

			# Otherwise, place the piece and flip captured pieces
			# Complicated HTML to allow each piece to have a white + black side
			piece = $('<div class="piece"><div class="white"></div><div class="black"></div>').data('color', 'white')

			square.append piece

			# Animate into view
			piece.animate { 'opacity': 1 }, 200

			# Flip to black if necessary
			if @currentPlayer is 'black' then piece.animate({ 'rotateY': '180deg' }).data('color', 'black')

			# Flip captured pieces
			captured.forEach (group, i) =>
				if group.length != undefined
					group.forEach (pieceIndex, j) =>
						piece = @board.children('div').eq(pieceIndex).children('.piece')
						# Determine when to rotate to 180deg (black) and when to rotate to 0deg (white)
						# TODO: Slightly delay the flip of each piece
						if piece.data('color') is 'white'
							piece.animate { 'rotateY': '180deg' }, 250
						else
							piece.animate { 'rotateY': '0deg' }, 250
						# Set the new color
						piece.data 'color', @currentPlayer

			@updateScore()

			# Randomly just keeping track of how many rounds are played
			@turns += 1
			@incorrect = 0
			previousPlayer = @currentPlayer

			# Swap turn
			if @currentPlayer is "black" then @currentPlayer = "white" else @currentPlayer = "black"

			# Determine if there's a win condition
			validMoves = @canPlay @currentPlayer

			# Check to see if the next player can actually move
			if validMoves.length is 0
				# Check whether the other player can play again; if not, the game is over
				if @canPlay(previousPlayer).length is 0
					if @blackCount > @whiteCount
						winner = 'Black Wins!'
					else if @whiteCount > @blackCount
						winner = 'White Wins!'
					else
						winner = 'Tie Game!'

					@modal.show
						'title': "Game Over! #{winner}"
						'buttons': [
							{
								'text': 'Play Again'
								'callback': =>
									@reset()
							}, {
								'text': 'Quit'
								'callback': =>
									@trigger 'scene:change', 'title'
							}
						]

					# End the game center match
					GameCenter?.endMatch GameCenter.matches[@matchId].data
				else
					# If they can, then show a message saying that the current player's turn was skipped
					@modal.show
						'title': "#{@currentPlayer} can't play, so it's #{previousPlayer}'s turn."
						'buttons': [{'text': 'OK'} ]
					@currentPlayer = previousPlayer

					skipNextPlayer = true
					GameCenter?.advanceTurn GameCenter.matches[@matchId].data, skipNextPlayer
					# TODO: Advance the turn, while skipping the next player
			else
				# Advance Game Center data
				GameCenter?.advanceTurn GameCenter.matches[@matchId].data

			# Highlight the current player's score box
			$(".info > div", this.elem).removeClass 'turn'
			$(".info .#{@currentPlayer}", this.elem).addClass 'turn'

		###
		Update the piece count
		###
		updateScore: ->
			# Update the "count" display - this is brute force for now
			@blackCount = 0
			@whiteCount = 0
			$('.piece', @elem).each (i, element) =>
				if $(element).data('color') is 'black' then @blackCount += 1
				else @whiteCount += 1

			$('.black .count', @elem).html @blackCount
			$('.white .count', @elem).html @whiteCount

		###
		Checks whether or not there's a valid move anywhere for a particular player
		###
		canPlay: (color) ->
			# Cycle through board squares
			# If square is "open," check if it's a valid move for the specified color
			validSquares = []

			@board.children('div').each (i, square) =>
				# If already a piece in the square, potential move is invalid
				if $(square).children('.piece').length > 0 then return

				if @validate i, color then validSquares.push i

			return validSquares

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

			# Call our eight validation methods
			left = @validateLeft index, color
			up = @validateUp index, color
			right = @validateRight index, color
			down = @validateDown index, color

			upLeft = @validateUpperLeft index, color
			upRight = @validateUpperRight index, color
			downLeft = @validateLowerLeft index, color
			downRight = @validateLowerRight index, color

			# console.log [ left, upLeft, up, upRight, right, downRight, down, downLeft ]

			if not left and not upLeft and not up and not upRight and not right and not downRight and not down and not downLeft
				return false
			else
				return [ left, upLeft, up, upRight, right, downRight, down, downLeft ]

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

			while i >= j
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

			while i <= j
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
			topBorder = index % 8
			# If too close to the top of the board, automatically return false
			if index - 8 <= topBorder then return false

			piece = squares.eq(index - 8).children('.piece')
			# Check to see if the first square to the top exists, and is a different color
			if piece.length == 0 or piece.data('color') == color then return false

			# Now, search for a piece of the same color
			i = index - 16
			j = topBorder
			captured = [index - 8]

			while i >= j
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
		validateDown: (index, color) ->
			squares = @board.children('div')
			bottomBorder = 56 + index % 8

			# If too close to the bottom border of the board, automatically return false
			if index + 8 >= bottomBorder then return false

			piece = squares.eq(index + 8).children('.piece')
			# Check to see if the first square to the bottom exists, and is a different color
			if piece.length == 0 or piece.data('color') == color then return false

			# Now, search for a piece of the same color
			i = index + 16
			j = bottomBorder
			captured = [index + 8]

			while i <= j
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

			# If too close to the left or top border of the board, automatically return false
			if index - 1 <= leftBorder or index < 16 then return false

			# Check to see if the first square to the upper left exists, and is a different color
			piece = squares.eq(index - 9).children('.piece')
			if piece.length == 0 or piece.data('color') == color then return false

			captured = [index - 9]

			# Now, search for a piece of the same color
			i = index - 18
			j = index - (index - leftBorder) * 9 	# Determine upper-left most piece from the index

			# Handle condition when upper-left most piece is off the board
			while j < 0
				j += 9

			while i >= j
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
		@description One of eight validation methods; checks to the uppper right of a potentially placed piece
		@param {Number} index The board index of the (potentially) new piece
		@param {String} color The color of the (potentially) new piece
		###
		validateUpperRight: (index, color) ->
			squares = @board.children('div')
			rightBorder = Math.floor(index / 8) * 8 + 7

			# If too close to the right or top border of the board, automatically return false
			if index + 1 >= rightBorder or index < 16 then return false

			# Check to see if the first square to the upper right exists, and is a different color
			piece = squares.eq(index - 7).children('.piece')
			if piece.length == 0 or piece.data('color') == color then return false

			captured = [index - 7]

			# Now, search for a piece of the same color
			i = index - 14
			j = index - (rightBorder - index) * 7	# Determine upper-right most piece from the index

			# Handle condition when upper-right most piece is off the board
			while j < 0
				j += 7

			while i >= j
				piece = squares.eq(i).children('.piece')
				
				# If we hit an empty space before a same-color piece, nothing is valid in that direction
				if piece.length is 0 then return false

				# For a successful move, we have to encounter another piece of the same color
				if piece.data('color') is color then i = j else captured.push i

				i -= 7

			# If the "captured" array includes the last square, that means there were no opposite-colored pieces
			if captured.indexOf(j) != -1 then return false

			# Finally, we have a valid move, and are returning an array of square indices that contain "captured" pieces
			return captured

		###
		@description One of eight validation methods; checks to the lower left of a potentially placed piece
		@param {Number} index The board index of the (potentially) new piece
		@param {String} color The color of the (potentially) new piece
		###
		validateLowerLeft: (index, color) ->
			squares = @board.children('div')
			leftBorder = Math.floor(index / 8) * 8

			# If too close to the left or bottom border of the board, automatically return false
			if index - 1 <= leftBorder or index > 47 then return false

			# Check to see if the first square to the lower left exists, and is a different color
			piece = squares.eq(index + 7).children('.piece')
			if piece.length == 0 or piece.data('color') == color then return false

			captured = [index + 7]

			# Now, search for a piece of the same color
			i = index + 14
			j = index + (index - leftBorder) * 7 	# Determine lower-right most piece from the index

			# Handle condition when lower left most piece is off the board
			while j > 63
				j -= 7

			while i <= j
				piece = squares.eq(i).children('.piece')
				
				# If we hit an empty space before a same-color piece, nothing is valid in that direction
				if piece.length is 0 then return false

				# For a successful move, we have to encounter another piece of the same color
				if piece.data('color') is color then i = j else captured.push i

				i += 7

			# If the "captured" array includes the last square, that means there were no opposite-colored pieces
			if captured.indexOf(j) != -1 then return false

			# Finally, we have a valid move, and are returning an array of square indices that contain "captured" pieces
			return captured

		###
		@description One of eight validation methods; checks to the lower right of a potentially placed piece
		@param {Number} index The board index of the (potentially) new piece
		@param {String} color The color of the (potentially) new piece
		###
		validateLowerRight: (index, color) ->
			squares = @board.children('div')
			rightBorder = Math.floor(index / 8) * 8 + 7

			# If too close to the right or bottom border of the board, automatically return false
			if index + 1 >= rightBorder or index > 47 then return false

			# Check to see if the first square to the lower right exists, and is a different color
			piece = squares.eq(index + 9).children('.piece')
			if piece.length == 0 or piece.data('color') == color then return false

			captured = [index + 9]

			# Now, search for a piece of the same color
			i = index + 18
			j = index + (rightBorder - index) * 9 	# Determine lower-right most piece from the index

			# Handle condition when lower left most piece is off the board
			while j > 63
				j -= 9

			while i <= j
				piece = squares.eq(i).children('.piece')
				
				# If we hit an empty space before a same-color piece, nothing is valid in that direction
				if piece.length is 0 then return false

				# For a successful move, we have to encounter another piece of the same color
				if piece.data('color') is color then i = j else captured.push i

				i += 9

			# If the "captured" array includes the last square, that means there were no opposite-colored pieces
			if captured.indexOf(j) != -1 then return false

			# Finally, we have a valid move, and are returning an array of square indices that contain "captured" pieces
			return captured

		###
		@description Remove existing pieces, and reset the game
		###
		reset: ->
			@currentPlayer = "black"

			$(".info > div", this.elem).removeClass 'turn'
			$(".info .#{@currentPlayer}", this.elem).addClass 'turn'

			# Remove existing pieces
			$('.piece', @elem).remove()

			# Remove existing hints
			$('.hint', @elem).remove()

			@updateScore()

			@turns = 0
			@incorrect = 0

			# Add an "index" value to each board square
			@board.children('div').each (i, element) ->
				e = $(element)
				e.data 'index', i
				e.addClass 'square'
				e.append '<div class="hint"></div>'

		resize: (width, height, orientation) ->
			# Use Math.floor here to ensure the grid doesn't round up to be larger than width/height of container
			if orientation is 'landscape'
				boardWidth = Math.round(height * 0.95 / 8) * 8 	# Make sure grid background size is 95% of viewport and an even multiple of 8
				@board.width boardWidth
				@board.height boardWidth

				# Also resize the info pane so it's the same size as the board (for aesthetic purposes)
				$('.info', @elem).css
					'width': '33%'
					'height': boardWidth

				# Add some margin to the board, so it appears centered
				margin = (height - boardWidth) / 2
				@board.css { 'margin': "#{margin}px 0" }
				$('.info', @elem).css { 'margin': "#{margin}px 0" }

			else if orientation is 'portrait'
				boardWidth = Math.round(width * 0.95 / 8) * 8	# grid size is 95% of viewport and an even multiple of 8
				@board.width boardWidth
				@board.height boardWidth

				# Also resize the info pane so it's the same size as the board (for aesthetic purposes)
				$('.info', @elem).css
					'width': boardWidth
					'height': '33%'

				# Add some margin to the board, so it appears centered
				margin = (width - boardWidth) / 2
				@board.css { 'margin': "0 #{margin}px" }
				$('.info', @elem).css { 'margin': "0 #{margin}px" }

		###
		@description Takes an array representing current board state, and places pieces accordingly
		###
		restoreBoard: ->
			data = window.GameCenter.matches[@matchId].data
			i = data.length

			while i--
				color = data[i]

				if color is 0 then continue

				piece = $('<div class="piece"><div class="white"></div><div class="black"></div>').data('color', 'white')
				square = @board.eq i
				square.append piece

				# Animate into view
				piece.css { 'opacity': 1 }

				# Flip to black if necessary
				if color is 1
					piece.animate({ 'rotateY': '180deg' }).data('color', 'black')

		###
		@description Called before scene transitions in
		###
		show: (duration = 500, callback) ->
			super duration, callback

			@reset()

			# Load Game Center match
			if @matchId != null
				window.GameCenter.loadMatch @matchId, (data) =>
					try
						data = JSON.parse(data)
					catch e
						# Data format - "board" prop is 64 index array representing board state (0: empty, 1: black, 2: white)
						# "moves" prop stores the sequential moves in the game (e.g. 34, 36, 36, 46)
						data =
							'board': []
							'moves': []

						while data.board.length < 64
							data.board.push 0

					# Store in global var
					window.GameCenter.matches[@matchId].data = data
					
					@restoreBoard()
				, (error) =>
					alert error