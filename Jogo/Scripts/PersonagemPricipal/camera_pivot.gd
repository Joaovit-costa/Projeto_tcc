extends Node3D

@export var target: CharacterBody3D
@export var height := 7.0
@export var distanci := 3.5
@export var smooth_speed := 4.0

func _physics_process(delta):
	if not target:
		return

	var desired_position := target.global_position
	desired_position.y += height
	desired_position.z += distanci

	# fator de suavização CLAMPADO
	var t : float= clamp(smooth_speed * delta, 0.0, 1.0)

	global_position = global_position.lerp(desired_position, t)
