extends Node3D
class_name WorldModeController

const MAP_WIDTH := 64
const MAP_DEPTH := 64
const MAP_HEIGHT := 32
const WORLD_BOUNDS := Vector3i(MAP_WIDTH, MAP_HEIGHT, MAP_DEPTH)
const BLOCK_CATALOG: Array[Dictionary] = [
	{"id": &"grass", "label": "Grass", "color": Color(0.32, 0.75, 0.35)},
	{"id": &"dirt", "label": "Dirt", "color": Color(0.52, 0.34, 0.2)},
	{"id": &"stone", "label": "Stone", "color": Color(0.62, 0.62, 0.66)},
	{"id": &"water", "label": "Water", "color": Color(0.24, 0.46, 0.88)},
]

@onready var _status_label: Label = %StatusLabel
@onready var _placement_label: Label = %PlacementLabel
@onready var _library_list: ItemList = %TemplateLibraryList
@onready var _camera: Camera3D = %WorldCamera
@onready var _renderer: GridMapBlockRenderer = %GridRenderer
@onready var _ghost_root: Node3D = %GhostRoot

var _selected_template: BuildingTemplateDefinition
var _selected_template_index: int = -1
var _rotation_index: int = 0
var _ghost_origin: Vector3i = Vector3i.ZERO
var _ghost_preview_entries: Array[Dictionary] = []
var _ghost_valid: bool = false
var _ghost_mesh_nodes: Array[Node3D] = []

func _ready() -> void:
	var village := AppServices.session.village
	village.seed = Time.get_unix_time_from_system()
	village.placed_blocks = AppServices.world_generation.generate_height_map(MAP_WIDTH, MAP_DEPTH, village.seed)
	village.placed_buildings.clear()

	var world_state := AppServices.session.world_voxel_state
	world_state.cells = village.placed_blocks.duplicate(true)

	AppServices.pathfinding.configure(Rect3i(0, 0, 0, MAP_WIDTH, MAP_HEIGHT, MAP_DEPTH))
	_renderer.configure(BLOCK_CATALOG)
	_renderer.render_full(world_state)
	_refresh_template_library()
	_update_status()
	_set_placement_message("Choisissez un template, tournez-le (R), puis posez-le (Entrée ou bouton).", Color(0.82, 0.87, 0.92))

func _process(_delta: float) -> void:
	_update_ghost_preview()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				_rotation_index = (_rotation_index + 1) % 4
				_update_status()
				_update_ghost_preview()
			KEY_ENTER, KEY_KP_ENTER:
				_place_selected_template()

func _on_back_to_menu_pressed() -> void:
	AppState.set_mode(AppState.MODE_MENU)

func _on_open_template_builder_pressed() -> void:
	AppState.set_mode(AppState.MODE_TEMPLATE_BUILDER)

func _on_template_library_list_item_selected(index: int) -> void:
	_selected_template_index = index
	var templates := AppServices.session.template_catalog.templates
	if index < 0 or index >= templates.size():
		_selected_template = null
		_clear_ghost_preview()
		_set_placement_message("Template invalide.", Color(0.95, 0.5, 0.45))
		_update_status()
		return

	_selected_template = templates[index]
	_set_placement_message("Template '%s' sélectionné." % [_selected_template.display_name], Color(0.52, 0.9, 0.58))
	_update_status()
	_update_ghost_preview()

func _on_rotate_template_pressed() -> void:
	_rotation_index = (_rotation_index + 1) % 4
	_update_status()
	_update_ghost_preview()

func _on_place_template_pressed() -> void:
	_place_selected_template()

func _refresh_template_library() -> void:
	_library_list.clear()
	for template in AppServices.session.template_catalog.templates:
		_library_list.add_item("%s (%s)" % [template.display_name, String(template.archetype_id)])

func _update_status() -> void:
	var selected_name := _selected_template.display_name if _selected_template != null else "Aucun"
	_status_label.text = "World %dx%d | Templates: %d | Sélection: %s | Rotation: %d° | Bâtiments posés: %d" % [
		MAP_WIDTH,
		MAP_DEPTH,
		AppServices.session.template_catalog.templates.size(),
		selected_name,
		_rotation_index * 90,
		AppServices.session.village.placed_buildings.size(),
	]

func _update_ghost_preview() -> void:
	if _selected_template == null:
		_clear_ghost_preview()
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := _camera.project_ray_origin(mouse_pos)
	var ray_normal := _camera.project_ray_normal(mouse_pos)
	var ground_plane := Plane(Vector3.UP, 0.0)
	var hit: Variant = ground_plane.intersects_ray(ray_origin, ray_normal)
	if hit == null:
		_clear_ghost_preview()
		return

	var hit_point: Vector3 = hit
	var target_x := clampi(int(floor(hit_point.x)), 0, MAP_WIDTH - 1)
	var target_z := clampi(int(floor(hit_point.z)), 0, MAP_DEPTH - 1)
	var base_height := _surface_height_at(target_x, target_z)
	_ghost_origin = Vector3i(target_x, base_height + 1, target_z)

	var world_state := AppServices.session.world_voxel_state
	var evaluation := AppServices.template_placement.evaluate_placement(
		_selected_template,
		world_state,
		_ghost_origin,
		_rotation_index,
		WORLD_BOUNDS
	)
	_ghost_preview_entries = evaluation.get("block_instances", [])
	_ghost_valid = evaluation.get("is_valid", false)
	_render_ghost_preview(_ghost_preview_entries, _ghost_valid)

	if _ghost_valid:
		_set_placement_message("Zone valide. Placement possible.", Color(0.52, 0.9, 0.58))
	else:
		var errors: Array = evaluation.get("errors", [])
		if errors.is_empty():
			_set_placement_message("Zone invalide.", Color(0.95, 0.5, 0.45))
		else:
			_set_placement_message("Zone invalide: %s" % [errors[0]], Color(0.95, 0.5, 0.45))

func _surface_height_at(x: int, z: int) -> int:
	var highest := 0
	for y in range(0, MAP_HEIGHT):
		if AppServices.session.world_voxel_state.cells.has(Vector3i(x, y, z)):
			highest = y
	return highest

func _render_ghost_preview(entries: Array[Dictionary], is_valid: bool) -> void:
	for node in _ghost_mesh_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_ghost_mesh_nodes.clear()

	var tint := Color(0.36, 0.78, 0.95, 0.35) if is_valid else Color(0.95, 0.3, 0.3, 0.4)
	for entry in entries:
		var mesh_instance := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * 1.01
		mesh_instance.mesh = box

		var material := StandardMaterial3D.new()
		material.albedo_color = tint
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.no_depth_test = true
		mesh_instance.material_override = material

		var cell: Vector3i = entry.get("cell", Vector3i.ZERO)
		mesh_instance.position = Vector3(cell.x + 0.5, cell.y + 0.5, cell.z + 0.5)
		mesh_instance.rotation_degrees.y = float(int(entry.get("rotation", 0)) % 4) * 90.0
		_ghost_root.add_child(mesh_instance)
		_ghost_mesh_nodes.append(mesh_instance)

func _clear_ghost_preview() -> void:
	_ghost_valid = false
	_ghost_preview_entries.clear()
	for node in _ghost_mesh_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_ghost_mesh_nodes.clear()

func _place_selected_template() -> void:
	if _selected_template == null:
		_set_placement_message("Sélectionnez un template avant de poser.", Color(0.95, 0.5, 0.45))
		return
	if not _ghost_valid:
		_set_placement_message("Placement refusé: zone invalide.", Color(0.95, 0.5, 0.45))
		return

	var world_state := AppServices.session.world_voxel_state
	var evaluation := AppServices.template_placement.evaluate_placement(
		_selected_template,
		world_state,
		_ghost_origin,
		_rotation_index,
		WORLD_BOUNDS
	)
	if not evaluation.get("is_valid", false):
		_set_placement_message("Placement refusé: collisions ou hors limites.", Color(0.95, 0.5, 0.45))
		return

	var transformed_blocks: Array[Dictionary] = evaluation.get("block_instances", [])
	var transformed_objects: Array[Dictionary] = evaluation.get("object_instances", [])
	for entry in transformed_blocks:
		var cell: Vector3i = entry.get("cell", Vector3i.ZERO)
		var block_id: StringName = entry.get("block_id", &"grass")
		var rot: int = int(entry.get("rotation", 0))
		AppServices.block_placement.place_block(world_state, cell, block_id, rot)

	var village := AppServices.session.village
	village.placed_blocks = world_state.cells.duplicate(true)
	var instance := AppServices.template_placement.create_building_instance(
		_selected_template,
		_ghost_origin,
		_rotation_index,
		transformed_blocks,
		transformed_objects
	)
	village.placed_buildings.append(instance)

	_renderer.render_full(world_state)
	_update_status()
	_set_placement_message("Template '%s' posé avec succès." % [_selected_template.display_name], Color(0.52, 0.9, 0.58))
	_update_ghost_preview()

func _set_placement_message(message: String, color: Color) -> void:
	_placement_label.text = message
	_placement_label.modulate = color
