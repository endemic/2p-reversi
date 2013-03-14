###
pass args object like this
{
	title: "string"
	message: "string"
	buttons: [
		{
			text: 'OK'
			callback: ->
				dostuf()
		}
	]
}
###
define [
	'jquery'
	'underscore'
	'backbone'
	'cs!utilities/environment'
], ($, _, Backbone, Env) ->
	class Modal extends Backbone.View
		defaults:
			animationTime: 300
			animationType: 'fade'	# TODO
			doCallback: true
			buttons:
				text: 'OK'

		visible: false

		events: ->
			# Determine whether touchscreen or desktop
			if Env.mobile
				events =
					'touchstart .modal .button': 'action'
			else
				events =
					'click .modal .button': 'action'

		initialize: ->
			# Ensure correct 'this' context
			_.bindAll @

			# Reposition on window resize/orientation change
			$(window).on 'resize', @resize

			@elem = $('<div class="overlay"><div class="modal"></div></div>')

			# Hide this content initially
			@elem.css { opacity: 0, 'z-index': -1 }

			# Reference to just the content window
			@window = $('.modal', @elem)

			@render()

		render: ->
			@$el.append @elem

		show: (options) ->
			# Don't allow this method to be executed again until the window is dismissed
			if @visible is true then return

			@visible = true

			# Fill in any values missing from the @options object 
			@options = _.defaults options, @defaults

			# Create HTML content here
			html = ''

			if @options.title
				html += "<h3>#{@options.title}</h3>"

			if @options.message
				html += "<p>#{@options.message}</p>"

			for button in @options.buttons
				html += '<div class="button" data-action="' + button.text.toLowerCase() + '">' + button.text + '</div>'

			# Set the modal window content + position
			@window.html html

			@window.css
				left: (@$el.width() - @window.width()) / 2
				top: (@$el.height() - @window.height()) / 2

			@elem.css { opacity: 0, 'z-index': 999 }

			# Animate content into place
			@elem.animate { opacity: 1 }, @options.animationTime, 'ease-in-out'

		# Determine which button was clicked, call the appropriate callback, then close the dialog box view
		action: (e) ->
			e.preventDefault()

			# Allow button callback to only be activated once
			if @options.doCallback is false then return

			@options.doCallback = false

			buttonAction = $(e.target).attr 'data-action'

			# Play sound effect
			@trigger 'sfx:play', 'button'

			# Search through the buttons array, looking for the callback associated w/ the clicked button
			for button in @options.buttons
				if button.text.toLowerCase() is buttonAction and typeof button.callback is "function"
					_.delay button.callback, @options.animationTime

			# Animate modal to be transparent, then set a negative z-index
			@elem.animate { opacity: 0 }, @options.animationTime, 'ease-in-out', =>
				@elem.css { 'z-index': -1 }
				@visible = false

		# Update position of dialog box when orientation changes
		resize: (e) ->
			this.window.css
				left: (@$el.width() - @window.width()) / 2
				top: (@$el.height() - @window.height()) / 2

		# Remove the resize event listener
		onClose: ->
			$(window).off 'resize', @resize