extends Area3D

class_name HitBox

@export var damage_multiplayer = 1.0

var player = CharacterBody3D


func _ready()->void:
	monitoring = false
	
	collision_layer = 4
	collision_mask = 0 # Pois não precisamos checar nada a partir da Hitbox, apenas esperamos
