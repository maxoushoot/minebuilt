extends Node3D
class_name WorldModeController

const MAP_WIDTH := 64
const MAP_DEPTH := 64

var _generation := WorldGenerationService.new()
var _pathfinding := GridPathfindingService.new()
var _population := PopulationService.new()
var _logistics := LogisticsService.new()

var _state := VillageState.new()

@onready var _status_label: Label = %StatusLabel

func _ready() -> void:
	_state.seed = Time.get_unix_time_from_system()
	_state.placed_blocks = _generation.generate_height_map(MAP_WIDTH, MAP_DEPTH, _state.seed)
	_pathfinding.configure(Rect3i(0, 0, 0, MAP_WIDTH, 16, MAP_DEPTH))
	_status_label.text = "World generated with %d blocks" % [_state.placed_blocks.size()]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_toggle_fps_mode"):
		AppState.set_mode(AppState.MODE_IMMERSION)
