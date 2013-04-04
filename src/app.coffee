###
@description App controller; handles instantiating scenes, music, sfx
###
define [
	'jquery'
	'underscore'
	'backbone'
	'buzz'
	'cs!utilities/environment'
	'cs!data/manifest'
	'cs!views/title'
	'cs!views/about'
	'cs!views/game'
], ($, _, Backbone, Buzz, Env, Manifest, TitleScene, AboutScene, GameScene) ->
	
	# Extend local storage
	Storage.prototype.setObject = (key, value) ->
	    @setItem key, JSON.stringify value

	Storage.prototype.getObject = (key) ->
    	value = @getItem key
	    return value and JSON.parse value

	# Extend Backbone
	Backbone.View.prototype.close = ->
		@elem.remove()
		@undelegateEvents()

		if typeof @onClose == "function"
			@onClose()

	# Define app obj
	class App extends Backbone.View
		el: null
		activeScene: null
		scenes: {}
		sounds: {}
		music: {}

		initialize: ->
			# Ensure 'this' context is always correct
			_.bindAll @

			# Ensure any user data has expected defaults
			@initializeDefaults()

			# Set up audio/music
			@initializeAudio()

			@el = if @options.el? then @options.el else $('#app')

			# Add an additional class to game container if "installed" on iOS homescreen - currently unused
			if window.navigator.standalone then @el.addClass 'standalone'

			# Create all views here
			@scenes.title = new TitleScene { el: @el }
			@scenes.about = new AboutScene { el: @el }
			@scenes.game = new GameScene { el: @el }

			# Bind some event listeners to each scene
			for id, scene of @scenes
				scene.on 'scene:change', @changeScene
				scene.on 'sfx:play', @playSfx
				scene.on 'vfx:play', @playVfx
				scene.on 'music:play', @playMusic
				scene.on 'music:stop', @stopMusic

				# Hide each scene initially
				scene.hide 0

			# Set "active" scene
			@activeScene = @scenes.title

			# Do an initial resize of the content area to ensure a 2:3 ratio
			@resize()

			# And listen for further resize events (also handles orientationchange events)
			$(window).on 'resize', @resize

			# Prevent content from dragging around on touchscreens
			if Env.mobile
				$('body').on 'touchmove', (e) ->
					e.preventDefault()

			# Show the active scene after a slight delay, so user can view the amazing splash screen
			_.delay =>
				if Env.cordova then navigator.splashscreen.hide()	# Manually remove the Cordova splash screen; which prevents a white flash while UIWebView is initialized
				@activeScene.show()
			, 1000

		###
		@description Scene manager
		###
		changeScene: (scene, options) ->
			@activeScene.hide()

			if @scenes[scene]?
				@activeScene = @scenes[scene]

				# if options != undefined
				# Pass options through to new scene
				for key, value of options?
					@activeScene[key] = value
			else
				alert "Sorry, #{scene} isn't a scene. Redirecting to title..."
				@activeScene = @scenes.title

			@activeScene.show()

		###
		@description Play a sound effect!
		###
		playSfx: (id) ->
			# Consider user prefs
			if localStorage.getItem('playSfx') == "false" then return

			@sounds[id]?.play()

		###
		@description Play music!
		###
		playMusic: (id) ->
			# Consider user prefs
			if localStorage.getItem('playMusic') == "false" then return

			# Do nothing if the same track is currently being played
			if @currentMusic == id then return
			
			# Play the same track that was previously playing if no arg is passed
			if not id and @currentMusic then id = @currentMusic

			if @currentMusic then @music[@currentMusic].stop()

			@music[id]?.play()

			@currentMusic = id

		###
		@description Stop music!
		###
		stopMusic: ->
			if not @currentMusic then return

			@music[@currentMusic].stop()

			@currentMusic = null

		###
		@description Does some sort of visual effect on the whole screen (flash, shake, etc.)
		###
		playVfx: (type) ->
			@el.addClass type
			_.delay =>
				@el.removeClass type
			, 250

		###
		@description Enforces an universal aspect ratio for different screen sizes; called on init, window resize, and orientation change
		###
		resize: (e) ->
			# Attempt to force a 2:3 aspect ratio, so that the percentage-based CSS layout is consistant
			width = @el.width()
			height = @el.height()

			# This obj will be used to store how much padding is needed for each scene's container
			padding = 
				width: 0
				height: 0

			if width > height
				@el.removeClass('portrait').addClass('landscape')
				orientation = 'landscape'
			else 
				@el.removeClass('landscape').addClass('portrait')
				orientation = 'portrait'

			# Landscape
			# example, 1280 x 800 - correct 2:3 ratio is 1200 x 800
			# example, 1024 x 768 - correct 2:3 ratio is 1024 x 682

			# Aspect ratio to enforce
			ratio = 3 / 2

			# Started writing some commented-out psuedocode, but it turned out to be CoffeeScript, so I uncommented it.
			if orientation is 'landscape'
				if width / ratio > height 		# Too wide; add padding to width
					newWidth = height * ratio
					padding.width = width - newWidth
					width = newWidth
				else if width / ratio < height 	# Too high; add padding to height
					newHeight = width / ratio
					padding.height = height - newHeight
					height = newHeight

				$('body').css { 'font-size': "#{width * 0.1302}%" }		# Dynamically update the font size - 0.1302% font size per pixel in width

			else if orientation is 'portrait'
				if height / ratio > width 		# Too high; add padding to height
					newHeight = width * ratio
					padding.height = height - newHeight
					height = newHeight
				else if height / ratio < width 	# Too wide, add padding to width
					newWidth = height / ratio
					padding.width = width - newWidth
					width = newWidth

				$('body').css { 'font-size': "#{height * 0.1302}%" }	# Dynamically update the font size - 0.1302% font size per pixel in height

			# Add the calculated padding to each scene <div>
			@el.find('.scene .container').css
				width: width
				height: height
				padding: "#{padding.height / 2}px #{padding.width / 2}px"

			# Call a "resize" method on views that need the size on certain elements to be recalculated
			# e.g. @scenes.title.resize width, height, orientation
			@scenes.game.resize width, height, orientation

		### 
		@description Ensure that localStorage keys return expected results 
		###
		initializeDefaults: ->
			# Whether to play music/SFX
			if localStorage.getItem('playMusic') == null
				localStorage.setItem 'playMusic', true

			if localStorage.getItem('playSfx') == null
				localStorage.setItem 'playSfx', true

		###
		@description Handle instantiating audio objects
		###
		initializeAudio: ->
			# Handle being moved to the background in Cordova
			if Env.cordova
				document.addEventListener "pause", =>
					if typeof @activeScene.pause is "function" then @activeScene.pause()
					@stopMusic()
					@pausedMusic = @currentMusic
				, false

				# Handle resuming from background
				document.addEventListener "resume", =>
					@playMusic @pausedMusic
				, false

			# Load sounds
			for key, sound of Manifest.sounds
				if Env.cordova
					@sounds[key] = new Media("#{sound.src}.#{sound.formats[0]}")
				else
					@sounds[key] = new Buzz.sound sound.src,
						formats: sound.formats
						preload: true

			# Load music
			for key, music of Manifest.music
				if Env.cordova
					@music[key] = new Media("#{music.src}.#{music.formats[0]}")
				else
					@music[key] = new Buzz.sound music.src,
						formats: music.formats
						preload: true
						loop: true

	# Load the app; wait until "deviceready" event is fired, if necessary (Cordova only)
	if Env.cordova
		document.addEventListener "deviceready", ->
			window.app = new App
		, false
	else
		window.app = new App
	