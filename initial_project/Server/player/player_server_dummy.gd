extends CharacterBody3D
class_name ServerPlayerDummy

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
@onready var animation_player: AnimationPlayer = $character_soldier/AnimationPlayer


@onready var head: Node3D = $Head

var id:int
var hitboxes: Array[RID] = []

func _ready()->void:
	for bone in skeleton.get_children():
		for maybe_hitbox in bone.get_children():
			if maybe_hitbox is HitBox:
				hitboxes.append(maybe_hitbox.get_rid())
				maybe_hitbox.player = self

func update_body_geometry(player_data: Dictionary)->void:
	position = player_data[NetKeys.POS]
	rotation.y = player_data[NetKeys.ROT_Y]
	head.rotation.x = player_data[NetKeys.ROT_X]
	
	if player_data.has(NetKeys.ANIM_POS):
		set_anim(player_data[NetKeys.ANIM], player_data[NetKeys.ANIM_POS])
		set_rot_x_visuals(player_data[NetKeys.ROT_X])
	

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
	

func set_anim (anim_name:String, anim_pos:float)->void:
		animation_player.play(anim_name)
		animation_player.seek(anim_pos, true)
		animation_player.pause()
	
