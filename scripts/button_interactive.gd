extends Area2D

signal button_pressed
signal button_released

@export var press_depth: float = 10.0
@export var press_duration: float = 0.2

@onready var button_top: ColorRect = $ButtonTop
@onready var button_base: ColorRect = $ButtonBase

var is_pressed: bool = false
var original_top_position: Vector2
var bodies_on_button: int = 0

# Colors
const COLOR_INACTIVE = Color(0.4, 0.4, 0.4)  # Gray
const COLOR_ACTIVE = Color(0.8, 0.2, 0.2)    # Red

func _ready() -> void:
	if button_top:
		original_top_position = button_top.position
		button_top.color = COLOR_INACTIVE

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		bodies_on_button += 1
		if not is_pressed:
			_press_button()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		bodies_on_button -= 1
		if bodies_on_button <= 0 and is_pressed:
			bodies_on_button = 0
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
