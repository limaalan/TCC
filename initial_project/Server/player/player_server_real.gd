extends CharacterBody3D
class_name PlayerServerReal

const CharacterVisual = preload("res://player/character/character_visual.gd")
const ANIM_BLEND_TIME := 0.2
const MAX_HEALTH := 100
const PlayerPowerupController = preload("res://player/powerups/player_powerup_controller.gd")
const PowerupEffectData = preload("res://shared/powerups/powerup_effect_data.gd")
const WeaponAmmoInventory = preload("res://shared/weapons/weapon_ammo_inventory.gd")

var current_health := MAX_HEALTH
var lobby :Lobby
var grenades_left := 2
var ammo_inventory := WeaponAmmoInventory.new()
var powerup_controller: PlayerPowerupController

@export var character_visual: CharacterVisual


func _ready() -> void:
	ammo_inventory.clear_all_ammo()
	powerup_controller = PlayerPowerupController.new(self)


func set_anim(anim_name:String)->void:
	if character_visual == null:
		return

	if character_visual.is_game_animation_active(anim_name):
		return 

	character_visual.play_game_animation(anim_name, ANIM_BLEND_TIME)


func get_current_animation_position() -> float:
	if character_visual == null:
		return 0.0

	return character_visual.get_current_animation_position()


func spend_weapon_ammo(weapon_id: int) -> bool:
	return ammo_inventory.spend_for_shot(weapon_id)


func get_weapon_ammo(weapon_id: int) -> int:
	return ammo_inventory.get_ammo(weapon_id)


func add_weapon_ammo(weapon_id: int, amount: int) -> int:
	return ammo_inventory.add_ammo(weapon_id, amount)


func set_weapon_ammo(weapon_id: int, amount: int) -> void:
	ammo_inventory.set_ammo(weapon_id, amount)


func setup_spawn_ammo(selected_weapon_id: int) -> void:
	ammo_inventory.setup_spawn_ammo(selected_weapon_id)


func apply_powerup(effect: PowerupEffectData) -> void:
	if powerup_controller == null:
		return

	powerup_controller.apply_powerup(effect)


func get_damage_multiplier() -> float:
	if powerup_controller == null:
		return 1.0

	return powerup_controller.get_damage_multiplier()


func change_health(amount:int, maybe_damage_dealer:int = 0 )->void:
	current_health = clampi(current_health + amount , 0 , MAX_HEALTH)
	
	if current_health <= 0 :
		die(maybe_damage_dealer )

	lobby.update_health(name.to_int(), current_health, MAX_HEALTH, amount)
		
func die(killer_id)->void :
	lobby.player_died(name.to_int(), killer_id)

func update_grenades_left(new_amount:int)->void:
	grenades_left = new_amount
	lobby.update_grenades_left(name.to_int(), new_amount)
