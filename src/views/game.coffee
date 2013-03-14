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
					'touchstart .back': 'back'
					'touchstart .board > div': 'move'
			else
				events = 
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
			if square.hasClass('piece') then return

			# Simple validation
			# if @validMove() is false then return

			square.append """<div class="piece #{@currentTurn}"></div>"""

			# Check to see which pieces get flipped
			# Find the index of the current piece
			index = square.data 'index'

			# Go left until we find a same colored piece
			# Go right until we find a same colored piece
			# Go up until we find a same colored piece or
			i = index - 8
			while i > 0
				piece = @board.children('div').eq(i).children('.piece')
				
				debugger;

				# End condition
				if piece.length is 0 or piece.hasClass(@currentTurn) then i = 0

				piece.addClass @currentTurn

				i -= 8

			# Go down until we find a same colored piece
			# i = index + 8
			# while i < 64
			# 	piece = @board.children('div').eq(i).children('.piece')
			# 	console.log "checking #{i}"
				
			# 	# End condition
			# 	if piece is undefined or piece.hasClass(@currentTurn) then i = 64

			# 	piece.addClass @currentTurn

			# 	i += 8

			# Swap turn
			if @currentTurn is "black" then @currentTurn = "white" else @currentTurn = "black"

		checkWinCondition: ->
			console.log "Winning!"

		validMove: (squareId) ->
			console.log "Validating!"

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

			@currentTurn = "black"

			# Add an "index" value to each board square
			@board.find('div').each (i, element)->
				$(element).data 'index', i

			# Remove existing pieces
			@elem.find('.piece').remove()

			# Read previous game moves

			# Re-create the current game state