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

		navigation: (e) ->
			e.preventDefault()

			# Don't allow button to be activated more than once
			@undelegateEvents()

			view = $(e.target).data('view')

			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', view