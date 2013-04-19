###
@description Lists in-progress & ended Game Center matches
###
define [
	'jquery'
	'backbone'
	'cs!utilities/environment'
	'cs!views/common/scene'
	'text!templates/gamecenter.html'
], ($, Backbone, Env, Scene, template) ->
	class GameCenterScene extends Scene
		events: ->
			# Determine whether touchscreen or desktop
			if Env.mobile
				events =
					'touchstart .back': 'back'
					'touchstart .new': 'request'
			else
				events =
					'click .back': 'back'
					'click .new': 'request'

		initialize: ->
			@elem = $(template)
			@render()

			# Custom callbacks for Game Center methods
			window.GameCenter.foundMatch = (matchId) =>
				# Transition to the gameplay view
				@trigger 'scene:change', 'game', { 'matchId': matchId }

			window.GameCenter.matchError = (error) =>
				alert error

			window.GameCenter.matchCancelled = =>
				alert 'Matchmaking was cancelled'

		back: (e) ->
			e.preventDefault()

			# Don't allow button to be activated more than once
			@undelegateEvents()

			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', 'title'

		request: (e) ->
			e.preventDefault()

			@trigger 'sfx:play', 'button'

			# Request match for 2 players
			window.GameCenter.requestMatch 2, 2, null, (error) =>
				alert error

		show: (duration = 500, callback) ->
			console.log "Trying to load matches"
			window.GameCenter.loadMatches (matches) =>
				console.log "successfully loaded matches"

				# Populate the UI here
				# container = @$('ul')

				# if matches.length is 0 then container.append '<li>No current matches</li>'

				# _.each matches, (match) =>
				# 	if match.participants[0].alias == undefined
				# 		match.participants[0].alias = "Waiting for player";
					
				# 	if match.participants[1].alias == undefined
				# 		match.participants[1].alias = "Waiting for player";

				# 	participants = match.participants[0].alias + ' vs. ' + match.participants[1].alias

				# 	container.append '<li><span class="match" style="border: 1px solid #ccc;" data-id="' + match.matchId + '">' + participants + '</span><a data-id="' + match.matchId + '" class="close">X</a></li>'
			, (error) =>
				alert error

			super duration, callback