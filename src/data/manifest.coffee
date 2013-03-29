###
@description External asset manifeset
###
define () ->
	Manifest = 
		sounds: 
			button: 
				src: 'assets/sounds/button'
				formats: [ 'mp3', 'ogg' ]
			move: 
				src: 'assets/sounds/move'
				formats: [ 'mp3', 'ogg' ]
			error: 
				src: 'assets/sounds/error'
				formats: [ 'mp3', 'ogg' ]
		music: {}
		images: {}