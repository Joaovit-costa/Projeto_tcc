extends CharacterBody3D

@onready var player: Node3D = $Player
@onready var animation_tree: AnimationTree = $Player/Animation_player/AnimationTree
var suavizacao_da_animação = Vector2()
const SPEED = 5.0
const JUMP_VELOCITY = 4.5


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		var rotation_player = atan2(direction.x, direction.z)
		player.rotation.y = lerp(player.rotation.y, rotation_player, delta * 5)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	suavizacao_da_animação = lerp(suavizacao_da_animação, input_dir, delta * 10)
	animation_tree.set("parameters/blend_position", suavizacao_da_animação.length())

	move_and_slide()
