###
Try to determine some basic info about the current environment
###
define () ->
	agent = navigator.userAgent.toLowerCase()

	android = agent.match(/android/i)?.length > 0
	ios = agent.match(/ip(hone|od|ad)/i)?.length > 0
	firefox = agent.match(/firefox/i)?.length > 0

	# "mobile" here refers to a touchscreen - this is pretty janky
	mobile = agent.match(/mobile/i)?.length > 0 || android

	return {
		android: android
		ios: ios
		firefox: firefox
		mobile: mobile
		desktop: not mobile
		cordova: typeof cordova != "undefined"
	}