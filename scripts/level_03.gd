extends Node2D

signal level_complete

const PATIENCE_TIME: float = 5.0

@onready var player: CharacterBody2D = $Player
@onready var door: Node2D = $Door
@onready var timer_bar: ColorRect = $TimerBar
@onready var timer_fill: ColorRect = $TimerBar/TimerFill

var patience_timer: float = 0.0
var door_opened: bool = false

func _ready() -> void:
	door.player_entered.connect(_on_player_entered_door)
	_update_timer_bar()

func _process(delta: float) -> void:
	if door_opened:
		return

	# Check for any input
	if _has_any_input():
		# Reset timer on any input
		patience_timer = 0.0
		_update_timer_bar()
		return

	# Accumulate patience time
	patience_timer += delta
	_update_timer_bar()

	# Check if patience time reached
	if patience_timer >= PATIENCE_TIME:
		door_opened = true
		door.open_door()

func _has_any_input() -> bool:
	# Check movement keys
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		return true
	if Input.is_action_pressed("jump"):
		return true
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down"):
		return true
	return false

func _update_timer_bar() -> void:
	if timer_fill:
		var progress = patience_timer / PATIENCE_TIME
		timer_fill.scale.x = clamp(progress, 0.0, 1.0)
		# Change color as progress increases
		if progress < 0.5:
			timer_fill.color = Color(0.4, 0.4, 0.4)
		elif progress < 0.8:
			timer_fill.color = Color(0.5, 0.5, 0.3)
		else:
			timer_fill.color = Color(0.6, 0.3, 0.3)

func _on_player_entered_door() -> void:
	level_complete.emit()
