extends Node2D

signal door_opened
signal door_locked
signal player_entered

@export var open_duration: float = 0.5
@export var open_offset: float = -80.0

@onready var door_panel: ColorRect = $DoorPanel
@onready var door_frame: ColorRect = $DoorFrame
@onready var trigger_area: Area2D = $TriggerArea

var is_open: bool = false
var is_locked: bool = false
var original_panel_position: Vector2
var door_blocker: StaticBody2D = null

# Colors
const COLOR_DOOR_CLOSED = Color(0.3, 0.3, 0.3)  # Dark gray
const COLOR_DOOR_OPEN = Color(0.15, 0.15, 0.15)  # Darker
const COLOR_DOOR_LOCKED = Color(0.6, 0.15, 0.15)  # Red - locked
const COLOR_FRAME = Color(0.5, 0.5, 0.5)  # Medium gray
const COLOR_FRAME_LOCKED = Color(0.5, 0.2, 0.2)  # Red frame
const COLOR_EXIT_GLOW = Color(1.0, 1.0, 0.9, 0.3)  # Warm light

func _ready() -> void:
	if door_panel:
		original_panel_position = door_panel.position
		door_panel.color = COLOR_DOOR_CLOSED
	if door_frame:
		door_frame.color = COLOR_FRAME

	# Create physical blocker for closed door
	_create_blocker()

	# Connect trigger area
	if trigger_area:
		trigger_area.body_entered.connect(_on_trigger_body_entered)

func _create_blocker() -> void:
	door_blocker = StaticBody2D.new()
	door_blocker.collision_layer = 2  # Same as walls/ground
	door_blocker.collision_mask = 0
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(20, 100)  # Thin blocker matching door panel height
	shape.shape = rect
	shape.position = Vector2(0, 50)
	door_blocker.add_child(shape)
	add_child(door_blocker)

func open_door() -> void:
	if is_open or is_locked:
		return

	is_open = true

	# Remove blocker so player can enter
	if door_blocker:
		door_blocker.queue_free()
		door_blocker = null

	# Animate door sliding up
	var tween = create_tween()
	tween.tween_property(door_panel, "position:y", original_panel_position.y + open_offset, open_duration)
	tween.parallel().tween_property(door_panel, "color", COLOR_DOOR_OPEN, open_duration)

	door_opened.emit()

func close_door() -> void:
	if not is_open:
		return

	is_open = false

	# Re-create blocker
	if not door_blocker:
		_create_blocker()

	var tween = create_tween()
	tween.tween_property(door_panel, "position:y", original_panel_position.y, open_duration)
	tween.parallel().tween_property(door_panel, "color", COLOR_DOOR_CLOSED, open_duration)

func lock_door() -> void:
	if is_locked:
		return

	is_locked = true

	# Visual feedback - turn red
	var tween = create_tween()
	tween.tween_property(door_panel, "color", COLOR_DOOR_LOCKED, 0.2)
	if door_frame:
		tween.parallel().tween_property(door_frame, "color", COLOR_FRAME_LOCKED, 0.2)

	door_locked.emit()

func unlock_door() -> void:
	is_locked = false
	if door_panel:
		door_panel.color = COLOR_DOOR_CLOSED
	if door_frame:
		door_frame.color = COLOR_FRAME

func _on_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_open and not is_locked:
		player_entered.emit()
