###
@description Shows credits or something
###
define [
	'jquery'
	'backbone'
	'cs!utilities/environment'
	'cs!views/common/scene'
	'cs!views/common/modal'
	'text!templates/about.html'
], ($, Backbone, Env, Scene, Modal, template) ->
	class AboutScene extends Scene
		events: ->
			# Determine whether touchscreen or desktop
			if Env.mobile
				events =
					'touchstart .back': 'back' 
					'touchstart .showModal': 'showModal'
			else
				events =
					'click .back': 'back' 
					'click .showModal': 'showModal'

		initialize: ->
			@elem = $(template)

			# Instantiate a reusable modal, and attach it to this scene
			@modal = new Modal { el: @elem }

			# Listen for sfx events from the modal
			@modal.on 'sfx:play', (id) => 
				@trigger 'sfx:play', id

			@render()

		back: (e) ->
			e.preventDefault()

			# Don't allow button to be activated more than once
			@undelegateEvents()
			
			@trigger 'sfx:play', 'button'
			@trigger 'scene:change', 'title'

		showModal: (e) ->
			e.preventDefault()

			@trigger 'sfx:play', 'button'

			@modal.show
				title: 'This is a dialog box with customizable buttons.'
				buttons: [
					{ 
						text: 'Yes'
						callback: => 
							console.log "Execute whatever you want as a callback."
					}, {
						text: 'No'	# This button just dismisses the dialog box
					}
				]