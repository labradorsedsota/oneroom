extends Area2D

signal button_pressed
signal button_released

@export var press_depth: float = 10.0
@export var press_duration: float = 0.2
@export var allow_rigidbody: bool = false  # Allow RigidBody2D to trigger (for L9)
@export var require_stopped: bool = false  # Require velocity ~0 to trigger (for L8)
@export var velocity_threshold: float = 30.0  # Speed threshold for require_stopped

@onready var button_top: ColorRect = $ButtonTop
@onready var button_base: ColorRect = $ButtonBase

var is_pressed: bool = false
var original_top_position: Vector2
var bodies_on_button: Array[Node2D] = []
var solid_body: StaticBody2D = null

# Colors
const COLOR_INACTIVE = Color(0.4, 0.4, 0.4)  # Gray
const COLOR_ACTIVE = Color(0.8, 0.2, 0.2)    # Red

# Margin for the trigger zone extension (must be >= player half-width 15px)
const TRIGGER_MARGIN: float = 30.0

func _ready() -> void:
	if button_top:
		original_top_position = button_top.position
		button_top.color = COLOR_INACTIVE
	_create_solid_collision()

func _physics_process(_delta: float) -> void:
	# For require_stopped mode, check velocity each frame
	if require_stopped and bodies_on_button.size() > 0:
		var should_press = false
		for body in bodies_on_button:
			if _is_valid_trigger(body) and _is_stopped(body):
				should_press = true
				break

		if should_press and not is_pressed:
			_press_button()
		elif not should_press and is_pressed:
			_release_button()

func _is_valid_trigger(body: Node2D) -> bool:
	if body.is_in_group("player"):
		return true
	if allow_rigidbody and body is RigidBody2D:
		return true
	return false

func _is_stopped(body: Node2D) -> bool:
	if not require_stopped:
		return true
	if body is CharacterBody2D:
		return body.velocity.length() < velocity_threshold
	if body is RigidBody2D:
		return body.linear_velocity.length() < velocity_threshold
	return true

func _on_body_entered(body: Node2D) -> void:
	if _is_valid_trigger(body):
		bodies_on_button.append(body)
		# For non-require_stopped mode, press immediately
		if not require_stopped and not is_pressed:
			_press_button()

func _on_body_exited(body: Node2D) -> void:
	if body in bodies_on_button:
		bodies_on_button.erase(body)
		if bodies_on_button.size() == 0 and is_pressed:
			_release_button()

func _press_button() -> void:
	is_pressed = true
	button_top.color = COLOR_ACTIVE

	# Animate button press
	var tween = create_tween()
	tween.tween_property(button_top, "position:y", original_top_position.y + press_depth, press_duration)

	button_pressed.emit()

func _release_button() -> void:
	is_pressed = false
	button_top.color = COLOR_INACTIVE

	# Animate button release
	var tween = create_tween()
	tween.tween_property(button_top, "position:y", original_top_position.y, press_duration)

	button_released.emit()

## Solid collision: prevents player from passing through the button
func _create_solid_collision() -> void:
	if not button_base or not button_top:
		return

	# Calculate full button bounds from visual elements
	var min_x = min(button_base.offset_left, button_top.offset_left)
	var max_x = max(button_base.offset_right, button_top.offset_right)
	var min_y = min(button_base.offset_top, button_top.offset_top)
	var max_y = max(button_base.offset_bottom, button_top.offset_bottom)

	var width = max_x - min_x
	var height = max_y - min_y
	var center_x = (min_x + max_x) / 2.0
	var center_y = (min_y + max_y) / 2.0

	# --- 1. Create StaticBody2D so the player can't walk/fall through ---
	solid_body = StaticBody2D.new()
	# Use layer 3 (value 4) instead of ground layer 2:
	# Player collision_mask=6 (layers 2+3) → collides with button ✓
	# RigidBody boxes (mask=3, layers 1+2) → pass through button ✓ (needed for L9)
	solid_body.collision_layer = 4
	solid_body.collision_mask = 0

	var solid_shape = RectangleShape2D.new()
	solid_shape.size = Vector2(width, height)

	var solid_col = CollisionShape2D.new()
	solid_col.shape = solid_shape
	solid_col.position = Vector2(center_x, center_y)

	solid_body.add_child(solid_col)
	add_child(solid_body)

	# --- 2. Extend the Area2D trigger zone so it detects the player ---
	# standing on top / touching the side of the solid body.
	# We add TRIGGER_MARGIN in every direction beyond the solid body bounds.
	var trigger = $CollisionShape2D
	if trigger:
		var new_trigger_shape = RectangleShape2D.new()
		new_trigger_shape.size = Vector2(
			width + TRIGGER_MARGIN * 2,
			height + TRIGGER_MARGIN * 2
		)
		trigger.shape = new_trigger_shape
		trigger.position = Vector2(center_x, center_y)
