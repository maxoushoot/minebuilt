extends Node3D
class_name WorldModeController

const MAP_WIDTH := 64
const MAP_DEPTH := 64

@onready var _status_label: Label = %StatusLabel

func _ready() -> void:
	var village := AppServices.session.village
	village.seed = Time.get_unix_time_from_system()
	village.placed_blocks = AppServices.world_generation.generate_height_map(MAP_WIDTH, MAP_DEPTH, village.seed)
	AppServices.pathfinding.configure(Rect3i(0, 0, 0, MAP_WIDTH, 16, MAP_DEPTH))
	_status_label.text = "World generated with %d blocks" % [village.placed_blocks.size()]

func _on_back_to_menu_pressed() -> void:
	AppState.set_mode(AppState.MODE_MENU)

func _on_open_template_builder_pressed() -> void:
	AppState.set_mode(AppState.MODE_TEMPLATE_BUILDER)
