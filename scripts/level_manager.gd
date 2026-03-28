extends Node2D

signal level_completed(level_index: int)
signal level_changed(level_index: int)

const TOTAL_LEVELS = 15
const LEVEL_PATH_TEMPLATE = "res://scenes/levels/level_%02d.tscn"
const LEVEL_TIME_LIMIT = 30.0  # seconds per level

var current_level_index: int = 1
var current_level_instance: Node = null
var time_remaining: float = LEVEL_TIME_LIMIT
var timer_active: bool = false

@onready var level_container: Node2D = $LevelContainer
@onready var hint_label: Label = $UI/HintLabel
@onready var level_label: Label = $UI/LevelLabel
@onready var timer_label: Label = $UI/TimerLabel

# Level hints from spec
var level_hints: Dictionary = {
	1: "Under Pressure",
	2: "Ignore It",
	3: "Hold Your Breath",
	4: "Hands On",
	5: "Don't Stop",
	6: "Carrying the Weight",
	7: "Upside Down",
	8: "Ice Floor",
	9: "Step Up",
	10: "Trust Your Gut",
	11: "Look Closer",
	12: "No Walls",
	13: "Tick Tock",
	14: "Say It",
	15: "Game Over"
}

func _ready() -> void:
	load_level(current_level_index)

func _process(delta: float) -> void:
	if timer_active:
		time_remaining -= delta
		_update_timer_display()
		if time_remaining <= 0:
			time_remaining = 0
			timer_active = false
			_on_time_up()

func _update_timer_display() -> void:
	if timer_label:
		var seconds = ceili(time_remaining)
		timer_label.text = "%d" % seconds
		# Turn red when < 10 seconds
		if time_remaining <= 10.0:
			timer_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
		else:
			timer_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))

func _on_time_up() -> void:
	# Time's up - restart from level 1
	load_level(1)

func load_level(level_index: int) -> void:
	if level_index < 1 or level_index > TOTAL_LEVELS:
		push_error("Invalid level index: %d" % level_index)
		return

	# Clear current level
	if current_level_instance:
		current_level_instance.queue_free()
		current_level_instance = null

	# Load new level
	var level_path = LEVEL_PATH_TEMPLATE % level_index
	if ResourceLoader.exists(level_path):
		var level_scene = load(level_path)
		current_level_instance = level_scene.instantiate()
		level_container.add_child(current_level_instance)

		# Connect level completion signal if exists
		if current_level_instance.has_signal("level_complete"):
			current_level_instance.level_complete.connect(_on_level_complete)

		current_level_index = level_index
		# Reset and start timer
		time_remaining = LEVEL_TIME_LIMIT
		timer_active = true
		_update_ui()
		level_changed.emit(current_level_index)
	else:
		push_error("Level not found: %s" % level_path)

func _update_ui() -> void:
	if hint_label:
		hint_label.text = '"%s"' % level_hints.get(current_level_index, "")
	if level_label:
		level_label.text = "L%d" % current_level_index
	_update_timer_display()

func _on_level_complete() -> void:
	# Stop timer and freeze player immediately
	timer_active = false
	_freeze_player()
	
	level_completed.emit(current_level_index)
	# Small delay before loading next level
	await get_tree().create_timer(0.5).timeout
	next_level()

func _freeze_player() -> void:
	if current_level_instance:
		var player = current_level_instance.get_node_or_null("Player")
		if player:
			player.set_physics_process(false)
			player.velocity = Vector2.ZERO

func next_level() -> void:
	if current_level_index < TOTAL_LEVELS:
		load_level(current_level_index + 1)
	else:
		# Game complete
		timer_active = false
		if timer_label:
			timer_label.text = "WIN!"
			timer_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2, 1))
		print("Congratulations! All levels completed!")

func restart_level() -> void:
	load_level(current_level_index)

func _input(event: InputEvent) -> void:
	# Debug: R to restart level
	if event.is_action_pressed("ui_cancel"):
		restart_level()
