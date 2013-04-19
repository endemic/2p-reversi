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
					'touchstart .match': 'loadMatch'
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

			# Get products user has already bought
			@purchased = localStorage.getObject 'purchased'

			# Custom callbacks for Game Center methods
			GameCenter.foundMatch = (matchId) =>
				index = 0

				# Transition to the gameplay view
				@trigger 'scene:change', 'game', { 'matchId': matchId }

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

			if @activeMatches > 1 and @purchased.indexOf('com.ganbarugames.reversi.unlimited-games') is -1
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

			matchId = $(e.target).data 'id'
			match = GameCenter.matches[matchId]

			# Check to see if game is in progress or finished
			# Show a modal w/ options for the ended game - view, remove, etc.
			if GameCenter.GKTurnBasedMatchStatus[match.status] is 'GKTurnBasedMatchStatusEnded'
				@modal.show
					'title': 'Game Status'
					'buttons': [
						{
							'text': 'View'
							'callback': =>
								@trigger 'scene:change', 'game', { 'matchId': matchId }
						}, {
							'text': 'Remove'
							'callback': =>
								GameCenter.removeMatch matchId, =>
									@$("##{matchId}").remove()
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

			if matches.length is 0 then container.append '<li>No current matches! Why not start a new one?</li>'

			_.each matches, (match, id) =>
				if GameCenter.GKTurnBasedMatchStatus[match.status] != 'GKTurnBasedMatchStatusEnded' then @activeMatches += 1

				if match.participants[0].alias == undefined
					match.participants[0].alias = "Opponent";
				
				if match.participants[1].alias == undefined
					match.participants[1].alias = "Opponent";

				text = "#{match.participants[0].alias} vs. #{match.participants[1].alias}<br>"
				if match.currentParticipant.playerId == GameCenter.authenticatedPlayer.playerId then text += "your turn" else text += "opponent's turn"

				container.append '<li id="' + id + '" class="match" data-id="' + id + '">' + text + '</li>'

		show: (duration = 500, callback) ->
			GameCenter.loadMatches (matches) =>
				# Store in global variable
				GameCenter.matches = matches
				@updateMatchList()
			, (error) =>
				alert error

			super duration, callback