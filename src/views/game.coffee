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

			# Simple validation
			# if @validMove() is false then return

			# Complicated HTML to allow each piece to have a white + black side
			piece = $('<div class="piece"><div class="white"></div><div class="black"></div>')

			square.append piece

			# Flip to black if necessary - use "animate" so vendor prefixes are automatically added
			if @currentPlayer is 'black'
				piece.css { '-webkit-transform': 'rotateY(180deg)' }

			# First 4 moves won't swap any other pieces, so skip the "swapping" logic
			if @turns < 4
				# Change active player turn
				if @currentPlayer is "black" then @currentPlayer = "white" else @currentPlayer = "black"
				@turns += 1
				return

			# Check to see which pieces get flipped
			# Find the index of the current piece
			index = square.data 'index'

			console.log "Clicked square: #{index}"

			# Some calculations can be left out here, because move validity is 
			# enforced prior to this code

			# Go left until we find a same colored piece
			i = index - 1
			j = Math.floor(index / 8) * 8
			while i > j
				piece = @board.children('div').eq(i).children('.piece')
				
				# End condition
				if piece.length is 0 or piece.data('color') is @currentPlayer then i = j

				piece.animate { 'transform': 'rotateY(180deg)' }, 250, 'ease-in-out'
				piece.data 'color', @currentPlayer

				i -= 1

			# Go right until we find a same colored piece
			i = index + 1
			j = Math.floor(index / 8) * 8 + 8
			while i < j
				piece = @board.children('div').eq(i).children('.piece')
				
				# End condition
				if piece.length is 0 or piece.data('color') is @currentPlayer then i = j

				piece.animate { 'transform': 'rotateY(180deg)' }, 250, 'ease-in-out'
				piece.data 'color', @currentPlayer

				i += 1

			# Go up until we find a same colored piece or
			i = index - 8
			j = 0
			while i > j
				piece = @board.children('div').eq(i).children('.piece')
				
				# End condition
				if piece.length is 0 or piece.data('color') is @currentPlayer then i = j

				piece.animate { 'transform': 'rotateY(180deg)' }, 250, 'ease-in-out'
				piece.data 'color', @currentPlayer

				i -= 8

			# Go down until we find a same colored piece
			i = index + 8
			j = 64
			while i < j
				piece = @board.children('div').eq(i).children('.piece')
				
				# End condition
				if piece.length is 0 or piece.data('color') is @currentPlayer then i = j

				piece.animate { 'transform': 'rotateY(180deg)' }, 250, 'ease-in-out'
				piece.data 'color', @currentPlayer

				i += 8

			# Swap turn
			if @currentPlayer is "black" then @currentPlayer = "white" else @currentPlayer = "black"

			@turns += 1

		checkWinCondition: ->
			console.log "Winning!"

		validMove: (squareId) ->
			console.log "Validating!"
			###
				Valid moves must be next to at least one piece of the opposite color
			###

			# Validation for first 4 moves just ensures they're at the center of the board
			if @turns < 4 and [27, 28, 36, 36].indexOf(squareId) is -1
				return false

			return true

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
			@board.find('div').each (i, element)->
				$(element).data 'index', i

			# Remove existing pieces
			@elem.find('.piece').remove()

			# Read previous game moves

			# Re-create the current game state