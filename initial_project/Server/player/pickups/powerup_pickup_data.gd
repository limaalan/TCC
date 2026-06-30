class_name PowerupPickupData
extends PickupData

@export var powerup_type: GameEnums.PowerupType = GameEnums.PowerupType.DAMAGE
@export var duration_sec := 10.0

@export_group("Damage")
@export var damage_multiplier := 1.0

@export_group("Fire Rate")
@export var fire_rate_cooldown_multiplier := 1.0
