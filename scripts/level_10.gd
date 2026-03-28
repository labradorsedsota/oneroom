extends Node2D

signal level_complete

@onready var player: CharacterBody2D = $Player
@onready var button: Area2D = $Button
@onready var door: Node2D = $Door
@onready var player_glow_outer: ColorRect = $PlayerGlow/Outer
@onready var player_glow_inner: ColorRect = $PlayerGlow/Inner
@onready var player_glow_core: ColorRect = $PlayerGlow/Core

var button_revealed: bool = false
var terrain_rects: Array[ColorRect] = []

func _ready() -> void:
	# Reset player physics
	if player:
		player.reset_physics()

	# Collect and hide all terrain visuals
	_collect_and_hide_terrain()

	# Connect button
	if button:
		button.button_pressed.connect(_on_button_pressed)
		button.body_entered.connect(_on_button_body_entered)
		# Hide button initially
		_hide_button()

	# Connect door entry to level completion
	if door:
		door.player_entered.connect(_on_player_entered_door)

func _process(_delta: float) -> void:
	# Update player glow position to follow player
	var glow_node = $PlayerGlow
	if glow_node and player:
		glow_node.global_position = player.global_position + Vector2(0, -25)

	# Animate glow pulsing
	var pulse = (sin(Time.get_ticks_msec() * 0.003) + 1.0) * 0.5
	if player_glow_outer:
		player_glow_outer.color.a = lerp(0.03, 0.06, pulse)
	if player_glow_inner:
		player_glow_inner.color.a = lerp(0.06, 0.10, pulse)
	if player_glow_core:
		player_glow_core.color.a = lerp(0.10, 0.15, pulse)

	# Animate door glow
	var door_glow = $DoorGlow
	if door_glow:
		var door_pulse = (sin(Time.get_ticks_msec() * 0.002 + 1.0) + 1.0) * 0.5
		door_glow.get_node("Outer").color.a = lerp(0.02, 0.05, door_pulse)
		door_glow.get_node("Inner").color.a = lerp(0.04, 0.08, door_pulse)

	# Animate button glow if revealed
	if button_revealed:
		var button_glow = button.get_node_or_null("ButtonGlow")
		if button_glow:
			var btn_pulse = (sin(Time.get_ticks_msec() * 0.005) + 1.0) * 0.5
			button_glow.color.a = lerp(0.15, 0.25, btn_pulse)

func _collect_and_hide_terrain() -> void:
	# Find all StaticBody2D children and hide their visual rects
	for child in get_children():
		if child is StaticBody2D:
			for subchild in child.get_children():
				if subchild is ColorRect:
					subchild.visible = false
					terrain_rects.append(subchild)

func _hide_button() -> void:
	var button_base = button.get_node_or_null("ButtonBase")
	var button_top = button.get_node_or_null("ButtonTop")
	var button_glow = button.get_node_or_null("ButtonGlow")
	if button_base:
		button_base.visible = false
	if button_top:
		button_top.visible = false
	if button_glow:
		button_glow.visible = false

func _reveal_button() -> void:
	if button_revealed:
		return
	button_revealed = true

	var button_base = button.get_node_or_null("ButtonBase")
	var button_top = button.get_node_or_null("ButtonTop")
	var button_glow = button.get_node_or_null("ButtonGlow")

	# Show with red color and fade-in
	if button_base:
		button_base.visible = true
		button_base.color = Color(0.3, 0.1, 0.1)
		button_base.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(button_base, "modulate:a", 1.0, 0.3)

	if button_top:
		button_top.visible = true
		button_top.color = Color(0.8, 0.2, 0.2)
		button_top.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(button_top, "modulate:a", 1.0, 0.3)

	if button_glow:
		button_glow.visible = true
		button_glow.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(button_glow, "modulate:a", 1.0, 0.3)

func _on_button_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_reveal_button()

func _on_button_pressed() -> void:
	_reveal_button()
	door.open_door()

func _on_player_entered_door() -> void:
	level_complete.emit()
