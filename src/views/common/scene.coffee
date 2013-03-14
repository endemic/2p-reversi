define [
	'jquery'
	'backbone'
	'cs!utilities/environment'
], ($, Backbone, Env) ->
	class Scene extends Backbone.View
		# Default action
		render: ->
			@$el.append @elem

		# Remove event handlers and hide this view's elem
		hide: (duration = 500, callback) ->
			@undelegateEvents()

			# Add class which transitions scene out of view
			@elem.addClass 'out'

			_.delay =>
				# Ideally, the scene should be offscreen after removing both these transition classes
				@elem.removeClass 'in'
				@elem.removeClass 'out'

				# Execute callback if supplied
				if typeof callback == "function" then callback()
			, duration
				
		# Re-delegate event handlers and show the view's elem
		show: (duration = 500, callback) ->
			@delegateEvents()

			# Add class which transitions scene into view
			@elem.addClass 'in'

			# Execute callback if supplied
			if typeof callback == "function" then _.delay callback, duration