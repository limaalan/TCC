class_name WeaponPresentationData
extends Resource

const AudioManagerScript = preload("res://game/audio/audio_manager.gd")

@export var id: GameEnums.WeaponId = GameEnums.WeaponId.PISTOL
@export var display_name: StringName = &"Pistol"
@export var weapon_scene: PackedScene
@export var selection_icon: Texture2D
@export var shoot_sfx: int = AudioManagerScript.SFXKeys.ShootPistol
@export var muzzle_fx_scene: PackedScene

@export var recoil_rotation_degrees := 15.0
@export var recoil_position_z := 0.05
@export var camera_shake_amount := 0.1
@export var pitch_randomness := 0.1
