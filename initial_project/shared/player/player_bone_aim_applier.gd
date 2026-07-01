extends RefCounted
class_name PlayerBoneAimApplier

const PlayerBoneAimConfig = preload("res://shared/player/player_bone_aim_config.gd")

static func build_cache(skeleton: Skeleton3D, config: PlayerBoneAimConfig) -> Dictionary:
	var cache := {}

	if skeleton == null or config == null:
		return cache

	for entry in config.entries:
		if entry == null:
			continue

		var bone_idx := skeleton.find_bone(String(entry.bone_name))
		if bone_idx == -1:
			push_warning("PlayerBoneAimApplier: bone '%s' not found." % entry.bone_name)
			continue

		cache[entry.bone_name] = bone_idx

	return cache


static func apply(
	skeleton: Skeleton3D,
	config: PlayerBoneAimConfig,
	rot_x: float,
	cache: Dictionary
) -> void:
	if skeleton == null or config == null:
		return

	var weight := inverse_lerp(config.min_camera_rot_x, config.max_camera_rot_x, rot_x)
	weight = clampf(weight, 0.0, 1.0)

	for entry in config.entries:
		if entry == null:
			continue

		var bone_idx := int(cache.get(entry.bone_name, -1))
		if bone_idx == -1:
			continue

		var current_rotation := skeleton.get_bone_pose_rotation(bone_idx)
		var euler := current_rotation.get_euler()
		var down := Vector3(
			deg_to_rad(entry.look_down_rotation_degrees.x),
			deg_to_rad(entry.look_down_rotation_degrees.y),
			deg_to_rad(entry.look_down_rotation_degrees.z)
		)
		var up := Vector3(
			deg_to_rad(entry.look_up_rotation_degrees.x),
			deg_to_rad(entry.look_up_rotation_degrees.y),
			deg_to_rad(entry.look_up_rotation_degrees.z)
		)

		if entry.apply_x:
			euler.x = lerp_angle(down.x, up.x, weight)
		if entry.apply_y:
			euler.y = lerp_angle(down.y, up.y, weight)
		if entry.apply_z:
			euler.z = lerp_angle(down.z, up.z, weight)

		skeleton.set_bone_pose_rotation(
			bone_idx,
			Basis.from_euler(euler).get_rotation_quaternion()
		)
