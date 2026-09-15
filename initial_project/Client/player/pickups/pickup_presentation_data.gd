class_name PickupPresentationData
extends Resource

const AudioManagerScript = preload("res://game/audio/audio_manager.gd")

@export var pickup_type: GameEnums.PickupType = GameEnums.PickupType.HEALTH
@export var pickup_subtype := -1
@export var mesh_scene: PackedScene
@export var ready_material: Material
@export var not_ready_material: Material
@export var pickup_sfx: int = AudioManagerScript.SFXKeys.PickupHealth
