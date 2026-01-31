extends CharacterBody3D
class_name PlayerRemote
@onready var animation_player: AnimationPlayer = $character_soldier/AnimationPlayer

#Valors obtidos a partir do teste com o modelo, observando como fica melhor nas posições curvado pra cima e pra baixo
const NECK_ROT_SCALAR : PackedFloat32Array = [0.2 , -0.2]
const ABDOMEN_ROT_SCALAR: PackedFloat32Array = [0.17 , 0]
const TORSO_ROT_SCALAR: PackedFloat32Array = [ 0.19 , -0.15]
const ARM_X_ROT_SCALAR: PackedFloat32Array = [ 0.19 , 0]
const ARM_Y_ROT_SCALAR: PackedFloat32Array = [ -0.39 , -1.25]

@onready var skeleton: Skeleton3D = $character_soldier/CharacterArmature/Skeleton3D
@onready var bone_neck := skeleton.find_bone("Neck")
@onready var bone_torso := skeleton.find_bone("Torso")
@onready var bone_abdomen := skeleton.find_bone("Abdomen")
@onready var bone_upper_arm_r := skeleton.find_bone("UpperArm.R")

@onready var name_tag_player: Label3D = $NameTagPlayer
 
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
var display_name:String

func _ready() -> void:
	update_player_colors()
	update_name_tag()


	
func update_body_geometry(old_data: Dictionary , new_data:Dictionary, lerp_weight:float)->void:
	position = lerp(old_data.pos, new_data.pos, lerp_weight)
	rotation.y = lerp_angle(old_data.rot_y , new_data.rot_y , lerp_weight)
	set_anim(new_data.anim)
	set_rot_x_visuals(lerp_angle(old_data.rot_x, new_data.rot_x, lerp_weight))
	
func update_player_colors() -> void:
	var team_material = BLUE_MATERIAL if team == 0 else RED_MATERIAL
	helmet_mesh.set_surface_override_material(HELMET_SURFACE_SLOT, team_material)
	body_mesh.set_surface_override_material(BODY_PANTS_SLOT, team_material)
	body_mesh.set_surface_override_material(BODY_SHIRT_SLOT, team_material)
	body_mesh.set_surface_override_material(BODY_SKIN_SLOT, SKIN_MATERIALS.pick_random()) 
	# cor da PELE do personagem escolhida aleatoriamente, 
	# informação não vem do servidor é apenas local

func set_rot_x_visuals(rot_x:float)->void:
	#90° olhando pra baixo -> -pi/2  , pra cima -> pi/2
	var rot_weight := remap(rot_x, -PI/2.0, PI/2.0 , 0, 1 )
	
	#Rotação do pescoço
	var q_neck := skeleton.get_bone_pose_rotation(bone_neck) 
	q_neck.x = lerp_angle(NECK_ROT_SCALAR[0], NECK_ROT_SCALAR[1], rot_weight)
	skeleton.set_bone_pose_rotation( bone_neck, q_neck)
	
	#Rotação do torso
	var q_torso := skeleton.get_bone_pose_rotation(bone_torso) 
	q_torso.x = lerp_angle(TORSO_ROT_SCALAR[0], TORSO_ROT_SCALAR[1], rot_weight)
	skeleton.set_bone_pose_rotation( bone_torso, q_torso)
	
	#Rotação do abdomen
	var q_abdomen := skeleton.get_bone_pose_rotation(bone_abdomen) 
	q_abdomen.x = lerp_angle(ABDOMEN_ROT_SCALAR[0], ABDOMEN_ROT_SCALAR[1], rot_weight)
	skeleton.set_bone_pose_rotation( bone_abdomen, q_abdomen)
	
	#Rotação do braço
	var q_upper_arm_r := skeleton.get_bone_pose_rotation(bone_upper_arm_r) 
	q_upper_arm_r.x = lerp_angle(ARM_X_ROT_SCALAR[0], ARM_X_ROT_SCALAR[1], rot_weight)
	q_upper_arm_r.y = lerp_angle(ARM_Y_ROT_SCALAR[0], ARM_Y_ROT_SCALAR[1], rot_weight)
	skeleton.set_bone_pose_rotation( bone_upper_arm_r, q_upper_arm_r)
	

func set_anim (anim_name:String)->void:
	if animation_player.assigned_animation == anim_name:
		return
	else:
		animation_player.play(anim_name,ANIM_BLEND_TIME)
	
func update_name_tag()->void:
	name_tag_player.text = display_name
