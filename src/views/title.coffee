###
@description Title or entry screen for yer app
###
define [
	'jquery'
	'backbone'
	'cs!utilities/environment'
	'cs!views/common/scene'
	'cs!views/common/modal'
	'text!templates/title.html'
], ($, Backbone, Env, Scene, Modal, template) ->
	class TitleScene extends Scene
		events: ->
			# Determine whether touchscreen or desktop
			if Env.mobile
				events =
					'touchstart .button': 'navigation'
			else
				events =
					'click .button': 'navigation'

		initialize: ->
			@elem = $(template)

			# Instantiate a reusable modal, and attach it to this scene
			@modal = new Modal { el: @elem }

			# Listen for sfx events from the modal
			@modal.on 'sfx:play', (id) => 
				@trigger 'sfx:play', id

			@render()

			if GameCenter?
				$('.gamecenter', @elem).css 'display', 'inline-block'

				@authenticated = false

				# Auto login
				GameCenter.authenticatePlayer (player) =>
					# Store player details
					GameCenter.authenticatedPlayer = player
					@authenticated = true
				, =>
					@authenticated = false
					console.log "Couldn't log in to Game Center."

		navigation: (e) ->
			e.preventDefault()
			@trigger 'sfx:play', 'button'

			view = $(e.target).data('view')

			# Show a message if there was a problem authenticating
			if view is 'gamecenter' and @authenticated is false
				@modal.show
					'title': "Uh Oh!"
					'message': "We couldn't log in to Game Center. Please log in using the Game Center app."
					'buttons': [
						{
							'text': 'OK'
						}
					]
				return

			# Don't scene change buttons to be activated more than once
			@undelegateEvents()
			@trigger 'scene:change', view