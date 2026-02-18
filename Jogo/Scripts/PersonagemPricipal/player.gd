extends CharacterBody3D
@onready var animation_tree: AnimationTree = $Player/Animacoes_player/AnimationTree
@onready var player: Node3D = $Player
@onready var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
@onready var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

# =========================
# CONFIGURAÇÕES
# =========================
@export var speed := 2.7
@export var sprint_speed := 4.0
@export var acceleration := 5.9
@export var friction := 25.0
@export var rotation_speed := 3.1
@export var jump_velocity := 3.2
@export var jump_delay := 0.4
@export var collider_normal_y := 0.65
@export var collider_crouch_y := 10.0
@export var collider_lerp_speed := 1.0

# =========================
# VARIÁVEIS
# =========================
var suavizacao_da_animacao: Vector2 = Vector2.ZERO
var transicion_animation := 0.0
var is_sprinting := false
var jump_requested := false
var jump_timer := 0.0
var current_speed : float

func _physics_process(delta: float) -> void:
	# =========================
	# GRAVIDADE
	# =========================
	if not is_on_floor():
		velocity += get_gravity() * delta

	# =========================
	# PULO
	# =========================
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() \
	and !animation_tree.get("parameters/OneShot/active"):
		jump_requested = true
		jump_timer = 0.0

		animation_tree.set(
			"parameters/OneShot/request",
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		)
	
	if jump_requested:
		jump_timer += delta
		if jump_timer >= jump_delay / 1.01:
			collision_shape_3d.position.y = lerp(
			collision_shape_3d.position.y,
			collider_crouch_y,
			delta * collider_lerp_speed)

		if jump_timer >= jump_delay:
			velocity.y = jump_velocity
			jump_requested = false
	else:
		collision_shape_3d.position.y = lerp(
		collision_shape_3d.position.y,
		collider_normal_y,
		delta * collider_lerp_speed * 1.6)
		
	# =========================
	# INPUT
	# =========================
	input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if is_on_floor() and !animation_tree.get("parameters/Combate/active"):
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# =========================
	# SPRINT
	# =========================
	is_sprinting = Input.is_action_pressed("run") and is_on_floor()
	if !animation_tree.get("parameters/Combate/active"):
		current_speed = sprint_speed if is_sprinting else speed
		
	# =========================
	# PUNCH
	# =========================
	if Input.is_action_pressed("Punching") and !animation_tree.get("parameters/Combate/active"):
		transicion_animation = lerp(transicion_animation, -0.4, delta * 10)

		animation_tree.set("parameters/BlendSpace1D/blend_position", transicion_animation)
		current_speed = 0.7
		
		animation_tree.set(
			"parameters/Combate/request",
			AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	# =========================
	# MOVIMENTO COM ACELERAÇÃO
	# =========================
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleration * delta)

		# Rotação suave do personagem
		var target_rotation := atan2(direction.x, direction.z)
		player.rotation.y = lerp_angle(
			player.rotation.y,
			target_rotation,
			rotation_speed * delta
		)
	else:
		# Desaceleração suave
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

	# =========================
	# ANIMAÇÃO (BLEND)
	# =========================
	suavizacao_da_animacao = suavizacao_da_animacao.lerp(input_dir, delta * 10)

	# Intensidade da animação (0 parado / 1 andando / >1 correndo)
	var horizontal_speed := Vector2(velocity.x, velocity.z).length() / sprint_speed
	var anim_blend := 0.0
	
	if is_sprinting and input_dir:
		anim_blend = 1.0
	elif horizontal_speed > 0.1:
		anim_blend = 0.4
	else:
		anim_blend = 0.0
	
	anim_blend = clamp(anim_blend, 0.0, 1.2)
	transicion_animation = lerp(transicion_animation, anim_blend, delta * 4)

	animation_tree.set("parameters/BlendSpace1D/blend_position", transicion_animation)

	# =========================
	# APLICAR MOVIMENTO
	# =========================
	move_and_slide()
