extends Node2D

signal level_complete

@onready var player: CharacterBody2D = $Player
@onready var button: Area2D = $Button
@onready var door: Node2D = $Door

func _ready() -> void:
	# Reset player physics first, then apply anti-gravity
	if player:
		player.reset_physics()
		# Flip gravity direction (negative = upward)
		player.gravity_direction = -1.0
		# Tell Godot that "floor" is now the ceiling
		player.up_direction = Vector2.DOWN
		# Enable floor snapping for better ceiling contact
		player.floor_snap_length = 10.0
		# Flip player sprite vertically
		player.scale.y = -1

	# Connect button to door
	if button:
		button.button_pressed.connect(_on_button_pressed)

	# Connect door entry to level completion
	if door:
		door.player_entered.connect(_on_player_entered_door)

func _on_button_pressed() -> void:
	door.open_door()

func _on_player_entered_door() -> void:
	level_complete.emit()
