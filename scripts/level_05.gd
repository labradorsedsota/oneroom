extends Node2D

signal level_complete

const JUMPS_REQUIRED: int = 5
const BUTTON_SQUASH_PER_JUMP: float = 3.0

@onready var player: CharacterBody2D = $Player
@onready var button: Area2D = $Button
@onready var button_top: ColorRect = $Button/ButtonTop
@onready var door: Node2D = $Door
@onready var indicators: Node2D = $Door/Indicators

var jump_count: int = 0
var player_on_button: bool = false
var player_was_in_air: bool = false
var door_opened: bool = false
var original_button_height: float = 0.0

# Indicator lights
var indicator_lights: Array[ColorRect] = []
const COLOR_LIGHT_OFF = Color(0.2, 0.2, 0.2)
const COLOR_LIGHT_ON = Color(0.8, 0.3, 0.3)

func _ready() -> void:
	# Connect button signals
	button.body_entered.connect(_on_button_body_entered)
	button.body_exited.connect(_on_button_body_exited)

	# Connect door entry to level completion
	door.player_entered.connect(_on_player_entered_door)

	# Store original button height
	if button_top:
		original_button_height = button_top.size.y

	# Get indicator lights
	_setup_indicators()

func _setup_indicators() -> void:
	indicator_lights.clear()
	if indicators:
		for child in indicators.get_children():
			if child is ColorRect:
				indicator_lights.append(child)
				child.color = COLOR_LIGHT_OFF

func _physics_process(_delta: float) -> void:
	if door_opened:
		return

	# Track if player is in the air
	if player and player_on_button:
		if not player.is_on_floor():
			player_was_in_air = true
		elif player_was_in_air:
			# Player just landed on button after being in air
			player_was_in_air = false
			_on_player_jump_land()

func _on_button_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_on_button = true
		# First landing counts as a jump
		if not player.is_on_floor():
			player_was_in_air = true

func _on_button_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_on_button = false
		player_was_in_air = false

func _on_player_jump_land() -> void:
	if door_opened:
		return

	jump_count += 1

	# Squash button more
	_squash_button()

	# Light up indicator
	_update_indicators()

	# Check if enough jumps
	if jump_count >= JUMPS_REQUIRED:
		door_opened = true
		_open_door_with_bounce()

func _squash_button() -> void:
	if not button_top:
		return

	# Calculate new height (gets smaller with each jump)
	var squash_amount = jump_count * BUTTON_SQUASH_PER_JUMP
	var new_height = max(original_button_height - squash_amount, 5.0)

	var tween = create_tween()
	tween.tween_property(button_top, "size:y", new_height, 0.1)
	tween.parallel().tween_property(button_top, "position:y",
		button_top.position.y + BUTTON_SQUASH_PER_JUMP * 0.5, 0.1)

	# Make button redder with each jump
	var progress = float(jump_count) / JUMPS_REQUIRED
	var new_color = Color(0.4 + 0.4 * progress, 0.4 - 0.2 * progress, 0.4 - 0.2 * progress)
	tween.parallel().tween_property(button_top, "color", new_color, 0.1)

func _update_indicators() -> void:
	for i in range(indicator_lights.size()):
		if i < jump_count:
			indicator_lights[i].color = COLOR_LIGHT_ON
		else:
			indicator_lights[i].color = COLOR_LIGHT_OFF

func _open_door_with_bounce() -> void:
	# Bounce animation before opening
	var tween = create_tween()
	tween.tween_property(door, "position:x", door.position.x + 5, 0.05)
	tween.tween_property(door, "position:x", door.position.x - 5, 0.05)
	tween.tween_property(door, "position:x", door.position.x, 0.05)
	tween.tween_callback(door.open_door)

func _on_player_entered_door() -> void:
	level_complete.emit()
