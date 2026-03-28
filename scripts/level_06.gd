extends Node2D

signal level_complete

@onready var player: CharacterBody2D = $Player
@onready var button: Area2D = $Button
@onready var door: Node2D = $Door

var shake_amount: float = 0.0
var original_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Reset player physics first, then apply heavy settings
	if player:
		player.reset_physics()
		# Heavy: 3x gravity, 0.5x speed
		player.gravity_scale = 3.0
		player.speed_multiplier = 0.5
		# Lower jump but still usable (max height ~51px vs normal ~103px)
		player.jump_velocity_override = -550.0
		# Connect landing for screen shake
		player.landed.connect(_on_player_landed)

	# Connect button to door
	if button:
		button.button_pressed.connect(_on_button_pressed)

	# Connect door entry to level completion
	if door:
		door.player_entered.connect(_on_player_entered_door)

	# Store original position for shake
	original_position = position

func _process(delta: float) -> void:
	# Apply screen shake by moving root node
	if shake_amount > 0:
		position = original_position + Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		shake_amount = lerp(shake_amount, 0.0, 10.0 * delta)
		if shake_amount < 0.5:
			shake_amount = 0.0
			position = original_position

func _on_player_landed() -> void:
	# Screen shake on landing (stronger with heavy gravity)
	shake_amount = 8.0

func _on_button_pressed() -> void:
	door.open_door()

func _on_player_entered_door() -> void:
	level_complete.emit()
