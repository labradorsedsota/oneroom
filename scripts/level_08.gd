extends Node2D

signal level_complete

@onready var player: CharacterBody2D = $Player
@onready var button: Area2D = $Button
@onready var door: Node2D = $Door
@onready var ice_particles: GPUParticles2D = $IceParticles

func _ready() -> void:
	# Reset player physics first, then apply slippery settings
	if player:
		player.reset_physics()
		# Enable friction mode for ice-like momentum-based physics
		player.friction_mode = true
		# Disable jumping
		player.jump_enabled = false

	# Configure button to require stopped state (velocity < 10)
	if button:
		button.require_stopped = true
		button.velocity_threshold = 10.0
		button.button_pressed.connect(_on_button_pressed)

	# Connect door entry to level completion
	if door:
		door.player_entered.connect(_on_player_entered_door)

func _physics_process(_delta: float) -> void:
	# Update ice particles position to follow player
	if ice_particles and player:
		ice_particles.global_position = player.global_position + Vector2(0, 30)
		# Only emit when player is moving
		ice_particles.emitting = abs(player.velocity.x) > 10

func _on_button_pressed() -> void:
	door.open_door()

func _on_player_entered_door() -> void:
	level_complete.emit()
