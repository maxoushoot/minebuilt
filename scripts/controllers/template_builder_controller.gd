extends Node3D
class_name TemplateBuilderController

const BUILD_AREA_SIZE := Vector2i(100, 100)
const MAX_BUILD_HEIGHT := 32
const BLOCK_CATALOG: Array[Dictionary] = [
	{"id": &"grass", "label": "Grass", "color": Color(0.32, 0.75, 0.35)},
	{"id": &"dirt", "label": "Dirt", "color": Color(0.52, 0.34, 0.2)},
	{"id": &"stone", "label": "Stone", "color": Color(0.62, 0.62, 0.66)},
]
const ARCHETYPE_DEFINITIONS: Array[TemplateArchetypeDefinition] = [
	preload("res://data/definitions/archetypes/house_archetype.tres"),
	preload("res://data/definitions/archetypes/school_archetype.tres"),
	preload("res://data/definitions/archetypes/townhall_archetype.tres"),
	preload("res://data/definitions/archetypes/farm_archetype.tres"),
	preload("res://data/definitions/archetypes/market_archetype.tres"),
	preload("res://data/definitions/archetypes/bridge_archetype.tres"),
	preload("res://data/definitions/archetypes/decor_archetype.tres"),
]
const FUNCTIONAL_OBJECT_DEFINITIONS: Array[FunctionalObjectDefinition] = [
	preload("res://data/definitions/objects/bed_basic.tres"),
	preload("res://data/definitions/objects/desk_basic.tres"),
	preload("res://data/definitions/objects/board_basic.tres"),
	preload("res://data/definitions/objects/admin_desk_basic.tres"),
	preload("res://data/definitions/objects/storage_basic.tres"),
	preload("res://data/definitions/objects/stall_basic.tres"),
	preload("res://data/definitions/objects/field_basic.tres"),
]
const EDIT_MODE_BLOCK := &"block"
const EDIT_MODE_OBJECT := &"object"

@onready var _status_label: Label = %StatusLabel
@onready var _hint_label: Label = %HintLabel
@onready var _validation_label: Label = %ValidationLabel
@onready var _camera: Camera3D = %BuildCamera
@onready var _renderer: GridMapBlockRenderer = %GridRenderer
@onready var _archetype_option: OptionButton = %ArchetypeOption
@onready var _object_option: OptionButton = %ObjectOption
@onready var _mode_label: Label = %EditModeLabel
@onready var _template_name_input: LineEdit = %TemplateNameInput
@onready var _library_list: ItemList = %TemplateLibraryList
@onready var _objects_root: Node3D = %ObjectsRoot

var _build_state: VoxelBuildState
var _active_block_index: int = 0
var _rotation_index: int = 0
var _build_layer: int = 0
var _ghost_cell: Vector3i = Vector3i.ZERO
var _ghost_valid: bool = false
var _selected_archetype: TemplateArchetypeDefinition
var _edit_mode: StringName = EDIT_MODE_BLOCK
var _object_entries: Array[Dictionary] = []
var _object_nodes_by_cell: Dictionary = {}
var _archetypes_by_index: Array[TemplateArchetypeDefinition] = []
var _objects_by_index: Array[FunctionalObjectDefinition] = []

func _ready() -> void:
	_build_state = AppServices.session.template_voxel_state
	_build_state.cells.clear()
	_object_entries.clear()
	_object_nodes_by_cell.clear()
	_build_layer = 0
	_rotation_index = 0
	_edit_mode = EDIT_MODE_BLOCK

	_populate_archetypes()
	_populate_functional_objects()

	_renderer.configure(BLOCK_CATALOG)
	_renderer.render_full(_build_state)
	_refresh_library()
	_update_status_text()
	_set_validation_message("Select an archetype, place blocks/objects, then validate.", Color(0.82, 0.87, 0.92))

func _process(_delta: float) -> void:
	_update_ghost_from_mouse()

func validate_sample(template: BuildingTemplateDefinition, archetype: TemplateArchetypeDefinition) -> Dictionary:
	return AppServices.template_validation.validate_template(template, archetype)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _edit_mode == EDIT_MODE_BLOCK:
				_try_place_block()
			else:
				_try_place_object()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if _edit_mode == EDIT_MODE_BLOCK:
				_try_remove_block()
			else:
				_try_remove_object()
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
			KEY_TAB:
				_toggle_edit_mode()

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
		return
	_try_remove_object()

func _try_place_object() -> void:
	if not _ghost_valid:
		return

	var selected_def := _selected_object_definition()
	if selected_def == null:
		_set_validation_message("No functional object selected.", Color(0.95, 0.5, 0.45))
		return
	if _object_nodes_by_cell.has(_ghost_cell):
		_set_validation_message("Cell already contains a functional object.", Color(0.95, 0.5, 0.45))
		return

	var entry := {
		"object_id": selected_def.id,
		"cell": _ghost_cell,
		"rotation": _rotation_index,
	}
	_object_entries.append(entry)
	_create_object_node(entry, selected_def)
	_update_status_text()

func _try_remove_object() -> void:
	if not _ghost_valid:
		return
	if not _object_nodes_by_cell.has(_ghost_cell):
		return

	var node: Node3D = _object_nodes_by_cell[_ghost_cell]
	if is_instance_valid(node):
		node.queue_free()
	_object_nodes_by_cell.erase(_ghost_cell)

	for index in range(_object_entries.size() - 1, -1, -1):
		var entry: Dictionary = _object_entries[index]
		if entry.get("cell", Vector3i.ZERO) == _ghost_cell:
			_object_entries.remove_at(index)
			break

	_update_status_text()

func _set_active_block(new_index: int) -> void:
	_active_block_index = clampi(new_index, 0, BLOCK_CATALOG.size() - 1)
	_update_status_text()

func _set_layer(new_layer: int) -> void:
	_build_layer = clampi(new_layer, 0, MAX_BUILD_HEIGHT - 1)
	_update_status_text()

func _update_status_text() -> void:
	var archetype_name := _selected_archetype.display_name if _selected_archetype else "None"
	_status_label.text = "Template zone (%dx%d) | Archetype: %s | Blocks: %d | Objects: %d" % [
		BUILD_AREA_SIZE.x,
		BUILD_AREA_SIZE.y,
		archetype_name,
		_build_state.cells.size(),
		_object_entries.size(),
	]
	var mode_text := "BLOCKS" if _edit_mode == EDIT_MODE_BLOCK else "OBJECTS"
	var selected_object := _selected_object_definition()
	var object_name := selected_object.display_name if selected_object else "N/A"
	_mode_label.text = "Edit mode: %s" % [mode_text]
	_hint_label.text = "Tab toggle mode | LMB place | RMB remove | 1-3 block | Q/E layer (%d) | R rotate (%d°) | Block: %s | Object: %s" % [
		_build_layer,
		_rotation_index * 90,
		_selected_block_label(),
		object_name,
	]

func _on_back_to_menu_pressed() -> void:
	AppState.set_mode(AppState.MODE_MENU)

func _on_open_world_mode_pressed() -> void:
	AppState.set_mode(AppState.MODE_WORLD)

func _on_archetype_option_item_selected(index: int) -> void:
	if index < 0 or index >= _archetypes_by_index.size():
		_selected_archetype = null
	else:
		_selected_archetype = _archetypes_by_index[index]
	_update_status_text()

func _on_object_option_item_selected(_index: int) -> void:
	_update_status_text()

func _on_validate_pressed() -> void:
	if _selected_archetype == null:
		_set_validation_message("Select an archetype before validation.", Color(0.95, 0.5, 0.45))
		return

	var template := _build_runtime_template("validation_preview")
	var result := AppServices.template_validation.validate_template(template, _selected_archetype)
	if result.get("is_valid", false):
		_set_validation_message("Validation succeeded for archetype '%s'." % [_selected_archetype.display_name], Color(0.52, 0.9, 0.58))
		return

	var errors: Array = result.get("errors", [])
	_set_validation_message("Validation failed:\n- %s" % ["\n- ".join(errors)], Color(0.95, 0.5, 0.45))

func _on_save_template_pressed() -> void:
	if _selected_archetype == null:
		_set_validation_message("Cannot save: no archetype selected.", Color(0.95, 0.5, 0.45))
		return

	var template_name := _template_name_input.text.strip_edges()
	if template_name.is_empty():
		_set_validation_message("Choose a template name before saving.", Color(0.95, 0.5, 0.45))
		return

	var template := _build_runtime_template(_slugify(template_name))
	template.display_name = template_name
	var validation := AppServices.template_validation.validate_template(template, _selected_archetype)
	if not validation.get("is_valid", false):
		var errors: Array = validation.get("errors", [])
		_set_validation_message("Save blocked. Missing requirements:\n- %s" % ["\n- ".join(errors)], Color(0.95, 0.5, 0.45))
		return

	AppServices.session.template_catalog.templates.append(template)
	_refresh_library()
	_set_validation_message("Template '%s' saved to library." % [template.display_name], Color(0.52, 0.9, 0.58))

func _on_clear_pressed() -> void:
	_build_state.cells.clear()
	_renderer.render_full(_build_state)
	for cell in _object_nodes_by_cell.keys():
		var node: Node3D = _object_nodes_by_cell[cell]
		if is_instance_valid(node):
			node.queue_free()
	_object_nodes_by_cell.clear()
	_object_entries.clear()
	_set_validation_message("Build area cleared.", Color(0.82, 0.87, 0.92))
	_update_status_text()

func _toggle_edit_mode() -> void:
	_edit_mode = EDIT_MODE_OBJECT if _edit_mode == EDIT_MODE_BLOCK else EDIT_MODE_BLOCK
	_update_status_text()

func _selected_object_definition() -> FunctionalObjectDefinition:
	var idx := _object_option.selected
	if idx < 0 or idx >= _objects_by_index.size():
		return null
	return _objects_by_index[idx]

func _populate_archetypes() -> void:
	_archetype_option.clear()
	_archetypes_by_index.clear()
	for archetype in ARCHETYPE_DEFINITIONS:
		_archetype_option.add_item(archetype.display_name)
		_archetypes_by_index.append(archetype)
	if not _archetypes_by_index.is_empty():
		_archetype_option.select(0)
		_selected_archetype = _archetypes_by_index[0]

func _populate_functional_objects() -> void:
	_object_option.clear()
	_objects_by_index.clear()
	for object_def in FUNCTIONAL_OBJECT_DEFINITIONS:
		_object_option.add_item(object_def.display_name)
		_objects_by_index.append(object_def)
	if not _objects_by_index.is_empty():
		_object_option.select(0)

func _build_runtime_template(id_suffix: String) -> BuildingTemplateDefinition:
	var template := BuildingTemplateDefinition.new()
	template.id = StringName("template_%s_%d" % [id_suffix, Time.get_unix_time_from_system()])
	template.display_name = id_suffix
	template.archetype_id = _selected_archetype.id if _selected_archetype else &""
	template.block_cells = _build_state.cells.keys()
	template.block_instances = []
	for cell_key in _build_state.cells.keys():
		var cell: Vector3i = cell_key
		var cell_data: Dictionary = _build_state.cells[cell]
		template.block_instances.append({
			"cell": cell,
			"block_id": cell_data.get("block_id", &"grass"),
			"rotation": int(cell_data.get("rotation", 0)),
		})
	template.object_instances = _object_entries.duplicate(true)
	template.object_placements = {}
	for entry in _object_entries:
		var object_id: StringName = entry.get("object_id", &"")
		if object_id != &"" and not template.object_placements.has(object_id):
			template.object_placements[object_id] = entry.get("cell", Vector3i.ZERO)
	return template

func _refresh_library() -> void:
	_library_list.clear()
	for template in AppServices.session.template_catalog.templates:
		_library_list.add_item("%s (%s)" % [template.display_name, String(template.archetype_id)])

func _set_validation_message(message: String, color: Color) -> void:
	_validation_label.text = message
	_validation_label.modulate = color

func _slugify(raw: String) -> String:
	var slug := raw.to_lower().strip_edges()
	slug = slug.replace(" ", "_")
	slug = slug.replace("-", "_")
	var cleaned := ""
	for c in slug:
		var code := c.unicode_at(0)
		var is_alnum := (code >= 48 and code <= 57) or (code >= 97 and code <= 122) or code == 95
		if is_alnum:
			cleaned += c
	return cleaned if not cleaned.is_empty() else "template"

func _create_object_node(entry: Dictionary, object_def: FunctionalObjectDefinition) -> void:
	var mesh_instance := MeshInstance3D.new()
	var footprint: Vector3 = Vector3(object_def.footprint_cells)
	var box := BoxMesh.new()
	box.size = Vector3(max(footprint.x, 1.0), max(footprint.y, 1.0), max(footprint.z, 1.0))
	mesh_instance.mesh = box

	var category_color := _category_color(object_def.category)
	var material := StandardMaterial3D.new()
	material.albedo_color = category_color
	mesh_instance.material_override = material

	var cell: Vector3i = entry.get("cell", Vector3i.ZERO)
	mesh_instance.position = Vector3(cell.x + 0.5, cell.y + 0.5, cell.z + 0.5)
	mesh_instance.rotation_degrees.y = float(int(entry.get("rotation", 0)) % 4) * 90.0
	mesh_instance.name = "Object_%s_%s" % [String(object_def.id), str(cell)]
	_objects_root.add_child(mesh_instance)
	_object_nodes_by_cell[cell] = mesh_instance

func _category_color(category: StringName) -> Color:
	match category:
		&"bed":
			return Color(0.85, 0.4, 0.66)
		&"bureau":
			return Color(0.45, 0.64, 0.88)
		&"tableau":
			return Color(0.25, 0.25, 0.25)
		&"bureau_administratif":
			return Color(0.7, 0.56, 0.32)
		&"stockage":
			return Color(0.54, 0.46, 0.35)
		&"etal":
			return Color(0.92, 0.72, 0.3)
		&"champ":
			return Color(0.26, 0.63, 0.27)
		_:
			return Color(0.78, 0.78, 0.78)
