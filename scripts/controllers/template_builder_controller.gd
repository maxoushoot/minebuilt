extends Node3D
class_name TemplateBuilderController

const BUILD_AREA_SIZE := Vector2i(100, 100)
const MAX_BUILD_HEIGHT := 32
const BLOCK_CATALOG: Array[Dictionary] = [
	{"id": &"grass", "label": "Grass", "color": Color(0.32, 0.75, 0.35)},
	{"id": &"dirt", "label": "Dirt", "color": Color(0.52, 0.34, 0.2)},
	{"id": &"stone", "label": "Stone", "color": Color(0.62, 0.62, 0.66)},
]

@onready var _status_label: Label = %StatusLabel
@onready var _hint_label: Label = %HintLabel
@onready var _camera: Camera3D = %BuildCamera
@onready var _renderer: GridMapBlockRenderer = %GridRenderer

var _build_state: VoxelBuildState
var _active_block_index: int = 0
var _rotation_index: int = 0
var _build_layer: int = 0
var _ghost_cell: Vector3i = Vector3i.ZERO
var _ghost_valid: bool = false

func _ready() -> void:
	_build_state = AppServices.session.template_voxel_state
	_renderer.configure(BLOCK_CATALOG)
	_renderer.render_full(_build_state)
	_update_status_text()

func _process(_delta: float) -> void:
	_update_ghost_from_mouse()

func validate_sample(template: BuildingTemplateDefinition, archetype: TemplateArchetypeDefinition) -> Dictionary:
	return AppServices.template_validation.validate_template(template, archetype)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place_block()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_try_remove_block()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_set_active_block(0)
			KEY_2:
				_set_active_block(1)
			KEY_3:
				_set_active_block(2)
			KEY_Q:
				_set_layer(_build_layer - 1)
			KEY_E:
				_set_layer(_build_layer + 1)
			KEY_R:
				_rotation_index = (_rotation_index + 1) % 4
				_update_status_text()

func _update_ghost_from_mouse() -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := _camera.project_ray_origin(mouse_pos)
	var ray_normal := _camera.project_ray_normal(mouse_pos)
	var build_plane := Plane(Vector3.UP, float(_build_layer))
	var hit: Variant = build_plane.intersects_ray(ray_origin, ray_normal)

	if hit == null:
		_ghost_valid = false
		_renderer.hide_ghost()
		return

	var hit_point: Vector3 = hit
	_ghost_cell = _renderer.world_to_cell(hit_point)
	_ghost_valid = _is_inside_build_bounds(_ghost_cell)

	if _ghost_valid:
		_renderer.set_ghost(_ghost_cell, _selected_block_id(), _rotation_index)
	else:
		_renderer.hide_ghost()

func _is_inside_build_bounds(cell: Vector3i) -> bool:
	if cell.x < 0 or cell.z < 0 or cell.y < 0:
		return false
	if cell.x >= BUILD_AREA_SIZE.x or cell.z >= BUILD_AREA_SIZE.y:
		return false
	return cell.y < MAX_BUILD_HEIGHT

func _selected_block_id() -> StringName:
	return BLOCK_CATALOG[_active_block_index]["id"]

func _selected_block_label() -> String:
	return BLOCK_CATALOG[_active_block_index]["label"]

func _try_place_block() -> void:
	if not _ghost_valid:
		return
	AppServices.block_placement.place_block(_build_state, _ghost_cell, _selected_block_id(), _rotation_index)
	_renderer.render_cell(_ghost_cell, _build_state.cells[_ghost_cell])
	_update_status_text()

func _try_remove_block() -> void:
	if not _ghost_valid:
		return
	if AppServices.block_placement.remove_block(_build_state, _ghost_cell):
		_renderer.clear_cell(_ghost_cell)
		_update_status_text()

func _set_active_block(new_index: int) -> void:
	_active_block_index = clampi(new_index, 0, BLOCK_CATALOG.size() - 1)
	_update_status_text()

func _set_layer(new_layer: int) -> void:
	_build_layer = clampi(new_layer, 0, MAX_BUILD_HEIGHT - 1)
	_update_status_text()

func _update_status_text() -> void:
	_status_label.text = "Template zone ready (%dx%d) | Blocks: %d" % [
		BUILD_AREA_SIZE.x,
		BUILD_AREA_SIZE.y,
		_build_state.cells.size(),
	]
	_hint_label.text = "LMB place | RMB remove | 1-3 block type | Q/E layer (%d) | R rotate (%d°) | Selected: %s" % [
		_build_layer,
		_rotation_index * 90,
		_selected_block_label(),
	]

func _on_back_to_menu_pressed() -> void:
	AppState.set_mode(AppState.MODE_MENU)

func _on_open_world_mode_pressed() -> void:
	AppState.set_mode(AppState.MODE_WORLD)
