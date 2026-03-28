extends Node2D

signal level_complete

@onready var player: CharacterBody2D = $Player
@onready var button: Area2D = $Button
@onready var door: Node2D = $Door
@onready var clickable_circle: Area2D = $ClickableCircle
@onready var circle_polygon: Polygon2D = $ClickableCircle/CirclePolygon

var circle_clicked: bool = false

const COLOR_CIRCLE_INACTIVE = Color(0.7, 0.2, 0.2)  # Red
const COLOR_CIRCLE_ACTIVE = Color(0.9, 0.4, 0.4)    # Bright red

func _ready() -> void:
	# Button press does nothing in this level (player stepping on it)
	# We don't connect button_pressed to door

	# Connect door entry to level completion
	door.player_entered.connect(_on_player_entered_door)

	# Set initial circle color
	if circle_polygon:
		circle_polygon.color = COLOR_CIRCLE_INACTIVE

func _input(event: InputEvent) -> void:
	if circle_clicked:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Check if click is on the circle
			var mouse_pos = get_global_mouse_position()
			var circle_pos = clickable_circle.global_position
			var distance = mouse_pos.distance_to(circle_pos)

			if distance <= 40.0:  # Circle radius
				_on_circle_clicked()

func _on_circle_clicked() -> void:
	circle_clicked = true

	# Visual feedback - glow and sink
	if circle_polygon:
		circle_polygon.color = COLOR_CIRCLE_ACTIVE

	# Animate circle pressing down
	var tween = create_tween()
	tween.tween_property(clickable_circle, "position:y", clickable_circle.position.y + 10, 0.2)
	tween.parallel().tween_property(clickable_circle, "scale", Vector2(1.0, 0.7), 0.2)

	# Open the door
	door.open_door()

func _on_player_entered_door() -> void:
	level_complete.emit()
