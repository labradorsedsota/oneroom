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
		# Flip player sprite vertically
		_flip_player_visual()

	# Connect button to door
	if button:
		button.button_pressed.connect(_on_button_pressed)

	# Connect door entry to level completion
	if door:
		door.player_entered.connect(_on_player_entered_door)

func _flip_player_visual() -> void:
	# Flip the player's visual components upside down
	var body_rect = player.get_node_or_null("BodyRect")
	var head_rect = player.get_node_or_null("HeadRect")

	if body_rect:
		body_rect.scale.y = -1
		# Adjust position to account for flip
		body_rect.position.y = -body_rect.position.y
	if head_rect:
		head_rect.scale.y = -1
		head_rect.position.y = -head_rect.position.y

func _on_button_pressed() -> void:
	door.open_door()

func _on_player_entered_door() -> void:
	level_complete.emit()
