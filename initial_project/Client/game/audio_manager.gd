extends Node

enum MusicKeys {
	MenuMusic, 
	BattleMusic
}
enum SFXKeys{
	UIClick,
	PickupHealth,
	PickupGrenade,
	ShootPistol,
	ShootSMG,
	ShootShotgun,
	Footstep,
	JumpLand,
	GrenadeThrow,
	GrenadeExplode
} # Acho que aqui daria pra colocar isso na configuração da propria arma...
const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const MUSIC_TARGET_VOLUME_DB := -16.0
const MUSIC_SILENT_VOLUME_DB := -60.0

@export var audio_library: AudioLibrary
@onready var music_player: AudioStreamPlayer = $MusicPlayer

var music_transition_tween :Tween

func _ready()->void:
	music_player.volume_db = MUSIC_SILENT_VOLUME_DB
	
func play_music(music_key: MusicKeys)->void:
	var stream := get_music_stream(music_key)
	if stream == null:
		push_warning("Music is not configured for key: %s" % music_key)
		return
	
	if music_transition_tween != null :
		music_transition_tween.kill()

	music_transition_tween = create_tween()
	if music_player.playing:
		music_transition_tween.tween_property(
			music_player,
			"volume_db",
			MUSIC_SILENT_VOLUME_DB,
			1.0
		)
		
	music_transition_tween.tween_callback(music_player.set_stream.bind(stream))
	music_transition_tween.tween_callback(music_player.play)
	
	music_transition_tween.tween_property(
		music_player,
		"volume_db",
		MUSIC_TARGET_VOLUME_DB,
		1.0
	)
	
#Pitch random pro som não ficar repetivo ( tiro da arma )
func play_sfx(sfx_key : SFXKeys, position:= Vector3.ZERO , pitch_rand := 0.0)->void:
	var stream := get_sfx_stream(sfx_key)
	if stream == null:
		push_warning("SFX is not configured for key: %s" % sfx_key)
		return

	var sfx_player
	if position == Vector3.ZERO:
		sfx_player = AudioStreamPlayer.new()
	else:
		sfx_player = AudioStreamPlayer3D.new()
		sfx_player.position = position
	
	sfx_player.stream = stream
	sfx_player.bus = SFX_BUS
	sfx_player.pitch_scale = 1 + randf_range(-pitch_rand , pitch_rand)
	sfx_player.finished.connect(sfx_player.queue_free)
	add_child(sfx_player)
	sfx_player.play()


func get_music_stream(music_key: MusicKeys) -> AudioStream:
	if audio_library == null:
		return null

	match music_key:
		MusicKeys.MenuMusic:
			return audio_library.menu_music
		MusicKeys.BattleMusic:
			return audio_library.battle_music

	return null


func get_sfx_stream(sfx_key: SFXKeys) -> AudioStream:
	if audio_library == null:
		return null

	match sfx_key:
		SFXKeys.UIClick:
			return audio_library.ui_click_sound
		SFXKeys.PickupHealth:
			return audio_library.health_pickup_sound
		SFXKeys.PickupGrenade:
			return audio_library.grenade_pickup_sound
		SFXKeys.ShootPistol:
			return audio_library.pistol_sound
		SFXKeys.ShootSMG:
			return audio_library.smg_sound
		SFXKeys.ShootShotgun:
			return audio_library.shotgun_sound
		SFXKeys.Footstep:
			return audio_library.footstep_sound
		SFXKeys.JumpLand:
			return audio_library.jump_sound
		SFXKeys.GrenadeThrow:
			return audio_library.grenade_throw_sound
		SFXKeys.GrenadeExplode:
			return audio_library.grenade_explosion_sound

	return null
