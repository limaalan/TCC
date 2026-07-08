extends RigidBody3D
class_name Grenade

const NetworkEntity = preload("res://shared/network_entity.gd")

@export var lifetime:= 2.0
@export var throw_impulse_strength := 20.0
@export var max_damage:= 150
@export var damage_radius := 4.0 #metros
@export var thrower_collision_exception_duration := 1.0

@onready var self_destruct_timer: Timer = $SelfDestructTimer
@onready var explosion_damage_area: Area3D = $ExplosionDamageArea
@onready var explosion_area_collision_shape: CollisionShape3D = $ExplosionDamageArea/CollisionShape3D

const HEIGHT_PADDING = 0.8 # valor somado à checagem de dano das granadas
# aproximadamente o peito do personagem , assim não checa a distância até o pé do personagem

var lobby : Lobby

var direction:Vector3
var thrower: PlayerServerReal
var network_id: StringName
var has_thrower_collision_exception := false

func set_data(_lobby:Lobby , _direction:Vector3 , _thrower:PlayerServerReal)->void:
	lobby = _lobby
	direction= _direction
	thrower = _thrower


func set_network_id(value: StringName) -> void:
	network_id = value


func get_network_id() -> String:
	if not NetworkEntity.require_id(network_id, "Grenade '%s'" % name):
		return ""

	return NetworkEntity.to_wire(network_id)

func _ready() -> void:
	if is_instance_valid(thrower):
		add_collision_exception_with(thrower) #evita que a granada colida imediatamente com o próprio jogador que jogou
		has_thrower_collision_exception = true
		get_tree().create_timer(thrower_collision_exception_duration).timeout.connect(_release_thrower_collision_exception, CONNECT_ONE_SHOT)
	else:
		push_warning("Grenade spawned without a valid thrower.")

	apply_central_impulse(direction * throw_impulse_strength)
	
	var explosion_area_shape := SphereShape3D.new()
	explosion_area_shape.radius = damage_radius
	explosion_area_collision_shape.shape = explosion_area_shape

	self_destruct_timer.wait_time = lifetime
	self_destruct_timer.start()


func _release_thrower_collision_exception() -> void:
	if not has_thrower_collision_exception:
		return

	has_thrower_collision_exception = false

	if not is_inside_tree():
		return

	if not is_instance_valid(thrower):
		return

	remove_collision_exception_with(thrower)

func _on_self_destruct_timer_timeout() -> void:
	explode()
	
func explode()->void:
	var killer_id := 0
	if is_instance_valid(thrower):
		killer_id = thrower.name.to_int()

	for body in explosion_damage_area.get_overlapping_bodies():
		var player := body as PlayerServerReal
		if player == null or not is_instance_valid(player):
			continue

		var distance := global_position.distance_to(player.global_position + Vector3.UP * HEIGHT_PADDING)
		var damage := roundi(max_damage - remap(clampf(distance, 0.0, damage_radius), 0.0, damage_radius, 0.0, float(max_damage)))
		player.change_health(-maxi(damage, 0), killer_id)

	if lobby != null and is_instance_valid(lobby):
		lobby.grenade_exploded(self)
	else:
		queue_free()
