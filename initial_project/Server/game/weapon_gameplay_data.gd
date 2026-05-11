class_name WeaponGameplayData
extends Resource

@export var id: int = GameEnums.WeaponId.PISTOL
@export var display_name := ""
@export var damage := 0
@export_range(0.0, 1.0) var accuracy := 1.0
@export var projectiles := 1


static func create(
	p_id: int,
	p_display_name: String,
	p_damage: int,
	p_accuracy: float,
	p_projectiles: int
) -> WeaponGameplayData:
	var data: WeaponGameplayData = new()
	data.id = p_id
	data.display_name = p_display_name
	data.damage = p_damage
	data.accuracy = p_accuracy
	data.projectiles = p_projectiles
	return data
