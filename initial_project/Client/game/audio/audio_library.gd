class_name AudioLibrary
extends Resource

@export_group("Music")
@export var menu_music: AudioStream
@export var battle_music: AudioStream

@export_group("Interface")
@export var ui_click_sound: AudioStream

@export_group("Weapons")
@export var pistol_sound: AudioStream
@export var smg_sound: AudioStream
@export var shotgun_sound: AudioStream

@export_group("Player")
@export var footstep_sound: AudioStream
@export var jump_sound: AudioStream

@export_group("Pickups")
@export var health_pickup_sound: AudioStream
@export var grenade_pickup_sound: AudioStream

@export_group("Grenades")
@export var grenade_throw_sound: AudioStream
@export var grenade_explosion_sound: AudioStream
