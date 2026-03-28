extends CharacterBody2D

# Default physics constants
const DEFAULT_SPEED = 300.0
const DEFAULT_JUMP_VELOCITY = -450.0
const DEFAULT_GRAVITY = 980.0
const DEFAULT_FRICTION = 0.2

@onready var body_rect: ColorRect = $BodyRect
@onready var head_rect: ColorRect = $HeadRect

var is_grounded: bool = false

# Configurable physics properties (modified by level scripts)
var speed_multiplier: float = 1.0
var gravity_scale: float = 1.0
var jump_enabled: bool = true
var jump_velocity_override: float = 0.0  # 0 means use default
var friction: float = DEFAULT_FRICTION  # Lower = more slippery
var gravity_direction: float = 1.0  # 1 = down, -1 = up (anti-gravity)
var friction_mode: bool = false  # Ice-like physics (low friction, momentum-based)

# Computed properties
var current_speed: float:
	get: return DEFAULT_SPEED * speed_multiplier
var current_gravity: float:
	get: return DEFAULT_GRAVITY * gravity_scale * gravity_direction
var current_jump_velocity: float:
	get:
		if jump_velocity_override != 0.0:
			return jump_velocity_override * gravity_direction
		return DEFAULT_JUMP_VELOCITY * gravity_direction

# Signals for level scripts to listen to
signal landed
signal jumped

var was_on_floor: bool = false

func _ready() -> void:
	# Player visual setup is done in the scene
	pass

func reset_physics() -> void:
	# Reset all physics properties to default
	speed_multiplier = 1.0
	gravity_scale = 1.0
	jump_enabled = true
	jump_velocity_override = 0.0
	friction = DEFAULT_FRICTION
	gravity_direction = 1.0
	friction_mode = false
	up_direction = Vector2.UP

	# Reset visual flip
	if body_rect:
		body_rect.scale.y = abs(body_rect.scale.y)
	if head_rect:
		head_rect.scale.y = abs(head_rect.scale.y)

func _physics_process(delta: float) -> void:
	var on_floor_now = is_on_floor()

	# Detect landing
	if on_floor_now and not was_on_floor:
		landed.emit()

	was_on_floor = on_floor_now

	# Apply gravity
	if not on_floor_now:
		velocity.y += current_gravity * delta
		is_grounded = false
	else:
		is_grounded = true

	# Handle jump
	if Input.is_action_just_pressed("jump") and on_floor_now and jump_enabled:
		velocity.y = current_jump_velocity
		jumped.emit()

	# Handle horizontal movement (A/D keys)
	var direction := Input.get_axis("move_left", "move_right")
	if friction_mode:
		# Ice-like physics: momentum-based movement with very low acceleration
		const ICE_ACCEL = 15.0  # Very slow acceleration on ice
		const ICE_DECEL = 5.0   # Even slower natural deceleration
		if direction:
			velocity.x += direction * ICE_ACCEL
			velocity.x = clampf(velocity.x, -current_speed, current_speed)
		else:
			velocity.x = move_toward(velocity.x, 0, ICE_DECEL)
	else:
		if direction:
			velocity.x = direction * current_speed
		else:
			# Use configurable friction for deceleration
			velocity.x = move_toward(velocity.x, 0, current_speed * friction)

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
