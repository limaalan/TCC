extends CharacterBody3D
class_name PlayerRemote
@onready var animation_player: AnimationPlayer = $character_soldier/AnimationPlayer

const ANIM_BLEND_TIME = 0.2
const RED_MATERIAL :StandardMaterial3D = preload("res://assets/materials/red_team_material.tres")
const BLUE_MATERIAL :StandardMaterial3D = preload("res://assets/materials/blue_team_material.tres")
const SKIN_MATERIALS := [
	preload("res://assets/materials/player_skin1.tres"),
	preload("res://assets/materials/player_skin2.tres"),
	preload("res://assets/materials/player_skin3.tres"),
]
@onready var helmet_mesh: MeshInstance3D = $character_soldier/CharacterArmature/Skeleton3D/Head_2/Head_2
const HELMET_SURFACE_SLOT = 1

@onready var body_mesh: MeshInstance3D = $character_soldier/CharacterArmature/Skeleton3D/Body
const BODY_SKIN_SLOT = 0
const BODY_PANTS_SLOT = 2
const BODY_SHIRT_SLOT = 3


var team :int

func _ready() -> void:
	update_player_colors()
	
func update_player_colors() -> void:
	var team_material = BLUE_MATERIAL if team == 0 else RED_MATERIAL
	helmet_mesh.set_surface_override_material(HELMET_SURFACE_SLOT, team_material)
	body_mesh.set_surface_override_material(BODY_PANTS_SLOT, team_material)
	body_mesh.set_surface_override_material(BODY_SHIRT_SLOT, team_material)
	body_mesh.set_surface_override_material(BODY_SKIN_SLOT, SKIN_MATERIALS.pick_random()) 
	# cor da PELE do personagem escolhida aleatoriamente, 
	# informação não vem do servidor é apenas local



func set_anim (anim_name:String)->void:
	if animation_player.assigned_animation == anim_name:
		return
	else:
		animation_player.play(anim_name,ANIM_BLEND_TIME)
	
