###
@description Title or entry screen for yer app
###
define [
	'jquery'
	'backbone'
	'cs!utilities/environment'
	'cs!views/common/scene'
	'text!templates/title.html'
], ($, Backbone, Env, Scene, template) ->
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
			@render()

			# Show the 2P Game Center button if plugin is available
			if typeof window.GameCenter != "undefined"
				$('.gamecenter', @elem).css 'display', 'inline-block'

		navigation: (e) ->
			e.preventDefault()

			# Don't allow button to be activated more than once
			@undelegateEvents()

			@trigger 'sfx:play', 'button'

			view = $(e.target).data('view')

			# Log into Game Center, then switch to the view that lists all games
			if view is 'gamecenter'
				window.GameCenter.authenticatePlayer =>
					@trigger 'scene:change', view
				, =>
					console.log "Couldn't log in to Game Center."
			else
				@trigger 'scene:change', view