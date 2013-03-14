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
					'touchstart .about': 'about'
			else
				events =
					'click .about': 'about'

		initialize: ->
			@elem = $(template)
			@render()

		about: (e) ->
			e.preventDefault()

			# Don't allow button to be activated more than once
			@undelegateEvents()

			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', 'about'