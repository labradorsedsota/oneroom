extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -450.0
const GRAVITY = 980.0

@onready var body_rect: ColorRect = $BodyRect
@onready var head_rect: ColorRect = $HeadRect

var is_grounded: bool = false

func _ready() -> void:
	# Player visual setup is done in the scene
	pass

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		is_grounded = false
	else:
		is_grounded = true

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle horizontal movement (A/D keys)
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.2)

	move_and_slide()

	# Simple squash and stretch animation
	_update_visual()

func _update_visual() -> void:
	# Squash when landing, stretch when jumping
	var target_scale_y = 1.0
	var target_scale_x = 1.0

	if velocity.y < -100:
		# Jumping - stretch vertically
		target_scale_y = 1.1
		target_scale_x = 0.9
	elif velocity.y > 100 and not is_on_floor():
		# Falling - slight stretch
		target_scale_y = 1.05
		target_scale_x = 0.95
	elif is_on_floor() and abs(velocity.y) < 10:
		# Grounded - normal
		target_scale_y = 1.0
		target_scale_x = 1.0

	body_rect.scale.y = lerp(body_rect.scale.y, target_scale_y, 0.2)
	body_rect.scale.x = lerp(body_rect.scale.x, target_scale_x, 0.2)
