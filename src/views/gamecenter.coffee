###
@description Lists in-progress & ended Game Center matches
###
define [
	'jquery'
	'underscore'
	'backbone'
	'cs!utilities/environment'
	'cs!views/common/scene'
	'cs!views/common/modal'
	'text!templates/gamecenter.html'
], ($, _, Backbone, Env, Scene, Modal, template) ->
	class GameCenterScene extends Scene
		events: ->
			# Determine whether touchscreen or desktop
			if Env.mobile
				events =
					'touchstart .back': 'back'
					'touchstart .new': 'newMatch'
					'touchend .match': 'loadMatch'
					'touchmove': _.throttle =>
						@scrolled = true
					, 100
					'touchend': =>
						@scrolled = false
			else
				events =
					'click .back': 'back'
					'click .new': 'newMatch'
					'click .match': 'loadMatch'

		productIds: [
			'com.ganbarugames.reversi.unlimited-games'
		]

		initialize: ->
			@elem = $(template)

			# Instantiate a reusable modal, and attach it to this scene
			@modal = new Modal { el: @elem }

			# Listen for sfx events from the modal
			@modal.on 'sfx:play', (id) => 
				@trigger 'sfx:play', id

			@render()

			# This allows users to scroll over multiple games by dragging
			@scrolled = false

			# Get products user has already bought
			@purchased = localStorage.getObject 'purchased'

			# Custom callbacks for Game Center methods
			GameCenter.foundMatch = (match) =>
				try
					match = JSON.parse match
				catch error
					@modal.show
						'title': 'Couldn\'t get game data :('
						'buttons': [
							{
								'text': 'OK',
								'callback': => 
									@trigger 'scene:change', 'title'
							}
						]
				
				# Push new obj representing the match onto the static GameCenter object
				GameCenter.matches[match.matchId] = match

				# Transition to the gameplay view
				@trigger 'scene:change', 'game', { 'matchId': match.matchId }

			GameCenter.matchError = (error) =>
				alert error

			GameCenter.matchCancelled = =>
				console.log 'Matchmaking was cancelled'

		back: (e) ->
			e.preventDefault()

			# Don't allow button to be activated more than once
			@undelegateEvents()

			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', 'title'

		###
		@description Create a new Game Center match - prompt to upgrade if user tries to create and has more than 2 active games
		###
		newMatch: (e) ->
			e.preventDefault()
			@trigger 'sfx:play', 'button'

			if @activeMatches > 100 and @purchased.indexOf('com.ganbarugames.reversi.unlimited-games') is -1
				@modal.show
					'title': 'Unlock Unlimited Games!'
					'message': "Play unlimited multiplayer games for only $0.99. Already unlocked? Hit the 'restore' button."
					'buttons': [
						{
							'text': 'Unlock'
							'callback': =>
								console.log 'Unlock'
						}, {
							'text': 'Restore'
							'callback': =>
								console.log 'Restore'
						}, {
							'text': 'Cancel'
						}
					]
			else
				# Request match for 2 players - GameCenter.foundMatch is called if successful
				GameCenter.requestMatch 2, 2, null, (error) =>
					alert error

		###
		@description Jump right into a game if it's in progress; if ended, show some options (view, remove, rematch, etc.)
		###
		loadMatch: (e) ->
			e.preventDefault()

			# Don't activate the game if the user was touching it while scrolling
			if @scrolled is true then return

			@trigger 'sfx:play', 'button'

			target = $(e.target)
			if target.hasClass('match') is false then target = target.parent('.match')

			matchId = target.data 'id'
			match = GameCenter.matches[matchId]

			# Check to see if game is in progress or finished
			# Show a modal w/ options for the ended game - view, remove, etc.
			# if GameCenter.GKTurnBasedMatchStatus[match.status] is 'GKTurnBasedMatchStatusEnded'
			if true
				@modal.show
					'title': 'Game Status'
					'buttons': [
						{
							'text': 'View'
							'callback': =>
								@trigger 'scene:change', 'game', { 'matchId': matchId }
						},{
							'text': 'Quit'
							'callback': =>
								GameCenter.quitMatch matchId, =>
									target.children('.status').html('game over')
								, (error) ->
									console.log "Error quitting match: #{error}"
						}, {
							'text': 'Remove'
							'callback': =>
								GameCenter.removeMatch matchId, =>
									target.animate { 'height': 0 }, 250, 'swing', ->
										$(@).remove()

									delete GameCenter.matches[matchId]

									# Find the # of current games
									totalMatches = 0
									_.each GameCenter.matches, (match, id) =>
										totalMatches += 1

									# Show the "create a game!" message if there are no current games
									if totalMatches is 0
										li = '<li>No current matches! Why not start a new one?</li>'
										@$('ul').append li

										li.animate { 'opacity': 0 }, 0, 'linear', ->
											li.animate { 'opacity': 1 }, 250
									
								, (error) ->
									console.log "Error removing match: #{error}"
						}, {
							'text': 'Cancel'
						}
					]
			# Go directly to the game
			else
				@trigger 'scene:change', 'game', { 'matchId': matchId }

		updateMatchList: ->
			# Populate the UI w/ appropriate matches here
			matches = GameCenter.matches
			container = @$('ul').empty()

			@activeMatches = 0
			totalMatches = 0

			_.each matches, (match, id) =>
				totalMatches += 1
				if GameCenter.GKTurnBasedMatchStatus[match.status] != 'GKTurnBasedMatchStatusEnded' then @activeMatches += 1

				if match.participants[0].alias == undefined
					match.participants[0].alias = "Opponent";
				
				if match.participants[1].alias == undefined
					match.participants[1].alias = "Opponent";

				text = "#{match.participants[0].alias} vs. #{match.participants[1].alias}<br>"

				if GameCenter.GKTurnBasedMatchStatus[match.status] is 'GKTurnBasedMatchStatusEnded' then text += '<span class="status">game over</span>'
				else if match.currentParticipant.playerId == GameCenter.authenticatedPlayer.playerId then text += '<span class="status">your turn</span>' else text += '<span class="status">opponent\'s turn</span>'

				container.append '<li class="match" data-id="' + id + '">' + text + '</li>'

			if totalMatches is 0 then container.append '<li>No current matches! Why not start a new one?</li>'

		show: (duration = 500, callback) ->
			if GameCenter.matches == null
				GameCenter.loadMatches (matches) =>
					# Store in global variable
					GameCenter.matches = matches
					@updateMatchList()
				, (error) =>
					@modal.show
						'title': error
						'buttons': [
							{
								'text': 'OK'
								'callback': =>
									@trigger 'scene:change', 'title'
							}
						]
			else
				@updateMatchList()

			super duration, callback