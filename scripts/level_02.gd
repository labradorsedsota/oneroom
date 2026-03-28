extends Node2D

signal level_complete

@onready var player: CharacterBody2D = $Player
@onready var button: Area2D = $Button
@onready var door: Node2D = $Door
@onready var door_sensor: Area2D = $DoorSensor

var button_was_pressed: bool = false

func _ready() -> void:
	# Connect button - if pressed, lock the door
	button.button_pressed.connect(_on_button_pressed)

	# Connect door sensor - auto open if player approaches without pressing button
	door_sensor.body_entered.connect(_on_door_sensor_entered)

	# Connect door entry to level completion
	door.player_entered.connect(_on_player_entered_door)

func _on_button_pressed() -> void:
	# Trap! Pressing the button locks the door
	button_was_pressed = true
	door.lock_door()

func _on_door_sensor_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not button_was_pressed:
		# Auto-open if player didn't press the button
		door.open_door()

func _on_player_entered_door() -> void:
	level_complete.emit()
