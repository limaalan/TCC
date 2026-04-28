extends Node

enum MusicKeys {
	MenuMusic, 
	BattleMusic
}
enum SFXKeys{
	UIClick,
	PickupHealth,
	PickupGrenade
}
@onready var music_player: AudioStreamPlayer = $MusicPlayer

var music_transition_tween :Tween

func _ready()->void:
	set_music_volume(0)
	
func play_music(music_key: MusicKeys)->void:
	var stream :AudioStream 
	match music_key:
		MusicKeys.MenuMusic:
			stream = load("res://assets/audio/music/Shrooter_Music_Menu.ogg")
		MusicKeys.BattleMusic:
			stream = load("res://assets/audio/music/Shrooter_Music_Gameplay.ogg")
	
	if music_transition_tween != null :
		music_transition_tween.kill()

	music_transition_tween = create_tween()
	if music_player.playing:
		music_transition_tween.tween_method(set_music_volume,1.0,0.0,1)
		
	music_transition_tween.tween_callback(music_player.set_stream.bind(stream))
	music_transition_tween.tween_callback(music_player.play)
	
	music_transition_tween.tween_method(set_music_volume,0.0,1.0,1)

	
func set_music_volume(volume_linear:float)->void:
	AudioServer.set_bus_volume_db(1, db_to_linear(volume_linear))
	
func play_sfx(sfx_key : SFXKeys)->void:
	var stream:AudioStream
	match sfx_key:
		SFXKeys.UIClick:
			stream = load("res://assets/audio/sfx/ui_click.ogg")
		SFXKeys.PickupHealth:
			stream = load("res://assets/audio/sfx/pickup_health.ogg")
		SFXKeys.PickupGrenade:
			stream = load("res://assets/audio/sfx/pickup_grenade.ogg")
	var sfx_player := AudioStreamPlayer.new()
	sfx_player.stream = stream
	sfx_player.bus = "SFX"
	sfx_player.finished.connect(sfx_player.queue_free)
	add_child(sfx_player)
	sfx_player.play()
