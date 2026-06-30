class_name WeaponDefinition
extends Resource

@export var id: GameEnums.WeaponId = GameEnums.WeaponId.PISTOL
@export var slot := 1
@export var display_name: StringName = &"Pistol"

@export_group("Shooting")
@export var damage := 0
@export_range(0.0, 1.0) var accuracy := 1.0
@export var projectiles := 1
@export var shot_cooldown := 0.3
@export var is_automatic := false

@export_group("Ammo")
@export var start_ammo := 0
@export var max_ammo := 0
@export var ammo_per_shot := 1
