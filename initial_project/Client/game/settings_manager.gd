extends Node

var mute_enabled := false 
var fullscreen_enabled := false 

func set_audio_mute (enabled :bool) ->void:
	mute_enabled = enabled
	AudioServer.set_bus_mute(AudioServer.get_bus_index(AudioManager.MASTER_BUS), enabled)
	
func set_fullscreen (enabled:bool) ->void:
	fullscreen_enabled = enabled
	var mode = DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
