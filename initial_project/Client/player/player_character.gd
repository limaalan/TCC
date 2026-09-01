extends CharacterBody3D
class_name PlayerCharacter

const HEALTH_GRADIENT := preload("res://player/player_info/health_gradient.tres")
const KEY_DAMAGE_MULTIPLIER := "damage_multiplier"
const KEY_FIRE_RATE_COOLDOWN_MULTIPLIER := "fire_rate_cooldown_multiplier"
const DAMAGE_POWERUP_COLOR := Color(1.0, 0.4, 0.2, 1.0)
const FIRE_RATE_POWERUP_COLOR := Color(0.3, 0.9, 1.0, 1.0)
@export var weapon_holder:WeaponHolder
@export var health_bar :ProgressBar
@export var powerup_visual: Node3D

var health_bar_fill_stylebox : StyleBoxFlat

var team:int
var weapon_id:int
var active_powerups: Dictionary = {}

func _ready()->void:
	instantiate_weapon()
	if health_bar != null :
		health_bar_fill_stylebox = health_bar.get_theme_stylebox("fill")
		update_health_bar(1,1,0)
	update_powerup_visuals()


func instantiate_weapon()->void:
	if weapon_holder == null :
		print("No weapon holder found on ", self)
		return
	weapon_holder.instantiate_weapon(weapon_id)


func set_weapon_id(new_weapon_id: int) -> void:
	if weapon_id == new_weapon_id and weapon_holder != null and weapon_holder.weapon != null:
		return

	weapon_id = new_weapon_id
	if is_inside_tree():
		instantiate_weapon()


func set_powerup_active(
	powerup_type: int,
	active: bool,
	damage_multiplier := 1.0,
	fire_rate_cooldown_multiplier := 1.0,
	_duration_sec := 0.0
) -> void:
	if active:
		active_powerups[powerup_type] = {
			KEY_DAMAGE_MULTIPLIER: damage_multiplier,
			KEY_FIRE_RATE_COOLDOWN_MULTIPLIER: fire_rate_cooldown_multiplier,
		}
	else:
		active_powerups.erase(powerup_type)

	update_powerup_visuals()


func get_fire_rate_cooldown_multiplier() -> float:
	if not active_powerups.has(GameEnums.PowerupType.FIRE_RATE):
		return 1.0

	return float(active_powerups[GameEnums.PowerupType.FIRE_RATE][KEY_FIRE_RATE_COOLDOWN_MULTIPLIER])


func update_powerup_visuals() -> void:
	if powerup_visual == null:
		return

	powerup_visual.visible = not active_powerups.is_empty()
	if powerup_visual is OmniLight3D:
		var powerup_light := powerup_visual as OmniLight3D
		powerup_light.light_color = get_powerup_visual_color()


func get_powerup_visual_color() -> Color:
	if active_powerups.has(GameEnums.PowerupType.DAMAGE):
		return DAMAGE_POWERUP_COLOR

	if active_powerups.has(GameEnums.PowerupType.FIRE_RATE):
		return FIRE_RATE_POWERUP_COLOR

	return FIRE_RATE_POWERUP_COLOR


func update_health_bar(current_health:int, max_health:int, changed_amount:int) ->void:
	if health_bar == null :
		return
	
	var new_value := current_health / float(max_health)
	health_bar.value = new_value
	health_bar_fill_stylebox.bg_color = HEALTH_GRADIENT.gradient.sample(new_value)
