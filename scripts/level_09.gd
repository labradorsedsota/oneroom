extends Node2D

signal level_complete

@onready var player: CharacterBody2D = $Player
@onready var button: Area2D = $Button
@onready var door: Node2D = $Door
@onready var trigger_zone: Area2D = $TriggerZone
@onready var box: RigidBody2D = $Box

var box_spawned: bool = false
var box_target_y: float = 0.0

func _ready() -> void:
	# Reset player physics
	if player:
		player.reset_physics()

	# Configure button to accept RigidBody2D (the box)
	if button:
		button.allow_rigidbody = true
		button.button_pressed.connect(_on_button_pressed)

	# Connect door entry to level completion
	if door:
		door.player_entered.connect(_on_player_entered_door)

	# Connect invisible trigger zone
	if trigger_zone:
		trigger_zone.body_entered.connect(_on_trigger_entered)

	# Hide box initially (below ground)
	if box:
		box_target_y = box.position.y
		box.position.y = box.position.y + 200
		box.freeze = true  # Don't apply physics until spawned

func _on_trigger_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not box_spawned:
		box_spawned = true
		_spawn_box()

func _spawn_box() -> void:
	if not box:
		return

	# Animate box rising from ground
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(box, "position:y", box_target_y, 0.5)
	tween.tween_callback(_enable_box_physics)

func _enable_box_physics() -> void:
	if box:
		box.freeze = false

func _on_button_pressed() -> void:
	door.open_door()

func _on_player_entered_door() -> void:
	level_complete.emit()
