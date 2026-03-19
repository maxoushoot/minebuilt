# GameRootController
# -----------------------------------------------------------------------------
# Architecture role: Controller (top-level scene router).
# Responsibilities:
# - Listens to AppState mode transitions.
# - Instantiates the scene matching the active mode.
# - Ensures only one mode scene is active at a time.
extends Node
class_name GameRootController

@export var menu_scene: PackedScene
@export var world_scene: PackedScene
@export var template_builder_scene: PackedScene
@export var immersion_scene: PackedScene

@onready var _content: Node = %Content

var _active_scene: Node

# Subscribes to global mode changes and initializes first scene.
func _ready() -> void:
	AppState.mode_changed.connect(_on_mode_changed)
	_switch_to(AppState.current_mode)

func _on_mode_changed(_previous_mode: StringName, next_mode: StringName) -> void:
	_switch_to(next_mode)

# Replaces current mode scene with the scene configured for the target mode.
func _switch_to(mode: StringName) -> void:
	if _active_scene:
		_active_scene.queue_free()
		_active_scene = null

	var packed := _scene_for_mode(mode)
	if packed == null:
		AppState.set_mode(AppState.MODE_MENU)
		return

	_active_scene = packed.instantiate()
	_content.add_child(_active_scene)

func _scene_for_mode(mode: StringName) -> PackedScene:
	match mode:
		AppState.MODE_MENU:
			return menu_scene
		AppState.MODE_WORLD:
			return world_scene
		AppState.MODE_TEMPLATE_BUILDER:
			return template_builder_scene
		AppState.MODE_IMMERSION:
			return immersion_scene
		_:
			return null
