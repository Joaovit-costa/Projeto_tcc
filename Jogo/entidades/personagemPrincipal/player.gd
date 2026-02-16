extends CharacterBody3D

@onready var player: Node3D = $Player
@onready var animation_tree: AnimationTree = $Player/Animation_player/AnimationTree

# =========================
# CONFIGURAÇÕES
# =========================
@export var speed := 2.5
@export var sprint_speed := 4.0
@export var acceleration := 4.5
@export var friction := 20.0
@export var rotation_speed := 2.7
@export var jump_velocity := 3.7

# =========================
# VARIÁVEIS
# =========================
var suavizacao_da_animacao: Vector2 = Vector2.ZERO
var transicion_animation := 0.0
var is_sprinting := false


func _physics_process(delta: float) -> void:
	# =========================
	# GRAVIDADE
	# =========================
	if not is_on_floor():
		velocity += get_gravity() * delta

	# =========================
	# PULO
	# =========================
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# =========================
	# INPUT
	# =========================
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# =========================
	# SPRINT
	# =========================
	is_sprinting = Input.is_action_pressed("run") and is_on_floor()
	var current_speed := sprint_speed if is_sprinting else speed

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
	anim_blend = clamp(anim_blend, 0.0, 1.0)
	transicion_animation = lerp(transicion_animation, anim_blend, delta * 4)

	animation_tree.set("parameters/blend_position", transicion_animation)

	# =========================
	# APLICAR MOVIMENTO
	# =========================
	move_and_slide()
