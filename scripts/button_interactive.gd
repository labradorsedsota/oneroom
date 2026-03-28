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

# Colors
const COLOR_INACTIVE = Color(0.4, 0.4, 0.4)  # Gray
const COLOR_ACTIVE = Color(0.8, 0.2, 0.2)    # Red

func _ready() -> void:
	if button_top:
		original_top_position = button_top.position
		button_top.color = COLOR_INACTIVE

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
