extends Node2D

signal level_complete

@onready var player: CharacterBody2D = $Player
@onready var button: Area2D = $Button
@onready var door: Node2D = $Door

func _ready() -> void:
	# Connect button to door
	button.button_pressed.connect(_on_button_pressed)

	# Connect door entry to level completion
	door.player_entered.connect(_on_player_entered_door)

func _on_button_pressed() -> void:
	door.open_door()

func _on_player_entered_door() -> void:
	level_complete.emit()
