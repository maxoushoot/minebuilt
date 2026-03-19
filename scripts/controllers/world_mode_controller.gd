# WorldModeController
# -----------------------------------------------------------------------------
# Architecture role: Controller (UI/input orchestration only).
# Responsibilities:
# - Orchestrates world-mode user input and view feedback.
# - Delegates business operations to use cases/services.
# - Renders placement preview and assignment/logistics UI state.
# Guardrail:
# - Business/domain logic must remain in services/use cases; this controller
#   should only coordinate flow: input -> validation/use case -> UI feedback.
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
@onready var _population_label: Label = %PopulationLabel
@onready var _logistics_label: Label = %LogisticsLabel
@onready var _placement_label: Label = %PlacementLabel
@onready var _library_list: ItemList = %TemplateLibraryList
@onready var _building_list: ItemList = %BuildingAssignmentList
@onready var _building_info_label: Label = %BuildingAssignmentInfoLabel
@onready var _villager_list: ItemList = %VillagerAssignList
@onready var _camera: Camera3D = %WorldCamera
@onready var _renderer: GridMapBlockRenderer = %GridRenderer
@onready var _ghost_root: Node3D = %GhostRoot
@onready var _logistics_actors_root: Node3D = %LogisticsActorsRoot

var _selected_template: BuildingTemplateDefinition
var _selected_template_index: int = -1
var _rotation_index: int = 0
var _ghost_origin: Vector3i = Vector3i.ZERO
var _ghost_preview_entries: Array[Dictionary] = []
var _ghost_valid: bool = false
var _ghost_mesh_nodes: Array[Node3D] = []

var _selected_building_index: int = -1
var _selected_assignable_index: int = -1
var _assignable_villager_ids: Array[int] = []
var _villager_actor_nodes: Dictionary = {}

# World mode bootstrap flow:
# - Bootstrap runtime.
# - Render world.
# - Initialize UI and assignment panels.
func _ready() -> void:
	AppServices.session_runtime.bootstrap_world_runtime(AppServices.session, MAP_WIDTH, MAP_DEPTH, MAP_HEIGHT)

	var world_state := AppServices.session.world_voxel_state
	_renderer.configure(BLOCK_CATALOG)
	_renderer.render_full(world_state)
	_refresh_template_library()
	_refresh_assignment_ui()
	_update_status()
	_set_placement_message("Choisissez un template, tournez-le (R), puis posez-le (Entrée ou bouton).", Color(0.82, 0.87, 0.92))

# Per-frame orchestration:
# - Update placement preview from cursor.
# - Advance logistics simulation and refresh visuals if needed.
func _process(_delta: float) -> void:
	_update_ghost_preview()
	var village := AppServices.session.village
	var logistics_tick := AppServices.logistics.tick(village, AppServices.pathfinding, _delta)
	if int(logistics_tick.get("deliveries", 0)) > 0:
		_update_status()
	_sync_villager_logistics_visuals()

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

func _on_building_assignment_list_item_selected(index: int) -> void:
	_selected_building_index = index
	_selected_assignable_index = -1
	_refresh_assignment_ui()

func _on_villager_assign_list_item_selected(index: int) -> void:
	_selected_assignable_index = index

# Controller flow: user assignment input -> use case execution -> UI feedback.
func _on_assign_villager_button_pressed() -> void:
	var village := AppServices.session.village
	var work_buildings := _work_buildings()
	if _selected_building_index < 0 or _selected_building_index >= work_buildings.size():
		_set_placement_message("Sélectionnez un bâtiment pour l'affectation.", Color(0.95, 0.5, 0.45))
		return
	if _selected_assignable_index < 0 or _selected_assignable_index >= _assignable_villager_ids.size():
		_set_placement_message("Sélectionnez un villageois libre.", Color(0.95, 0.5, 0.45))
		return

	var selected_building: BuildingInstance = work_buildings[_selected_building_index]
	var villager_id := _assignable_villager_ids[_selected_assignable_index]
	var result := AppServices.assign_villager_use_case.execute(village, villager_id, selected_building.id)
	if result.get("success", false):
		_set_placement_message("Villageois %d affecté à %s." % [villager_id, selected_building.template_name], Color(0.52, 0.9, 0.58))
	else:
		_set_placement_message(String(result.get("message", "Affectation impossible.")), Color(0.95, 0.5, 0.45))

	_selected_assignable_index = -1
	_refresh_assignment_ui()
	_update_status()

func _refresh_template_library() -> void:
	_library_list.clear()
	for template in AppServices.session.template_catalog.templates:
		_library_list.add_item("%s (%s)" % [template.display_name, String(template.archetype_id)])

func _update_status() -> void:
	var selected_name := _selected_template.display_name if _selected_template != null else "Aucun"
	var population_stats := AppServices.population.get_population_stats(AppServices.session.village)
	_status_label.text = "World %dx%d | Templates: %d | Sélection: %s | Rotation: %d° | Bâtiments posés: %d" % [
		MAP_WIDTH,
		MAP_DEPTH,
		AppServices.session.template_catalog.templates.size(),
		selected_name,
		_rotation_index * 90,
		AppServices.session.village.placed_buildings.size(),
	]
	_population_label.text = "Population totale: %d | Assignée: %d | Libre: %d" % [
		population_stats.get("total", 0),
		population_stats.get("assigned", 0),
		population_stats.get("free", 0),
	]
	var stocks := AppServices.session.village.resource_stocks
	_logistics_label.text = "Logistique V1 | Nourriture: %d | Bois: %d | Matériaux: %d" % [
		int(stocks.get("food", 0)),
		int(stocks.get("wood", 0)),
		int(stocks.get("materials", 0)),
	]

func _refresh_assignment_ui() -> void:
	_refresh_building_list()
	_refresh_assignable_villagers()
	_update_status()

func _refresh_building_list() -> void:
	var village := AppServices.session.village
	_building_list.clear()
	for building in village.placed_buildings:
		var capacity := max(building.worker_capacity, AppServices.population.worker_capacity_for_building(building))
		building.worker_capacity = capacity
		if capacity <= 0:
			continue
		_building_list.add_item("%s [%d/%d]" % [
			building.template_name,
			building.assigned_worker_ids.size(),
			capacity,
		])

	if _building_list.item_count == 0:
		_selected_building_index = -1
		_building_info_label.text = "Aucun bâtiment avec postes de travail disponible."
		return

	if _selected_building_index < 0 or _selected_building_index >= _building_list.item_count:
		_selected_building_index = 0
	_building_list.select(_selected_building_index)

	var selected := _work_buildings()[_selected_building_index]
	_building_info_label.text = "%s (capacité %d, assignés %d)" % [
		selected.template_name,
		selected.worker_capacity,
		selected.assigned_worker_ids.size(),
	]

func _refresh_assignable_villagers() -> void:
	_assignable_villager_ids.clear()
	_villager_list.clear()

	var work_buildings := _work_buildings()
	if _selected_building_index < 0 or _selected_building_index >= work_buildings.size():
		return

	var village := AppServices.session.village
	for villager in village.villagers:
		if villager.assigned_building_id != &"":
			continue
		_assignable_villager_ids.append(villager.id)
		_villager_list.add_item("%s [%s]" % [villager.display_name, String(villager.state)])

	if _assignable_villager_ids.is_empty():
		_villager_list.add_item("Aucun villageois libre")
		_selected_assignable_index = -1
		return

	if _selected_assignable_index < 0 or _selected_assignable_index >= _assignable_villager_ids.size():
		_selected_assignable_index = 0
	_villager_list.select(_selected_assignable_index)

func _work_buildings() -> Array[BuildingInstance]:
	var result: Array[BuildingInstance] = []
	for building in AppServices.session.village.placed_buildings:
		var capacity := max(building.worker_capacity, AppServices.population.worker_capacity_for_building(building))
		if capacity <= 0:
			continue
		building.worker_capacity = capacity
		result.append(building)
	return result

# Computes ghost placement by delegating authoritative validation to
# EvaluateTemplatePlacementUseCase (preview stage).
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

	var evaluation_result := AppServices.evaluate_template_placement_use_case.execute(
		AppServices.session,
		_selected_template,
		_ghost_origin,
		_rotation_index,
		WORLD_BOUNDS
	)
	var payload: Dictionary = evaluation_result.get("payload", {})
	_ghost_preview_entries = payload.get("block_instances", [])
	_ghost_valid = evaluation_result.get("success", false)
	_render_ghost_preview(_ghost_preview_entries, _ghost_valid)

	if _ghost_valid:
		_set_placement_message("Zone valide. Placement possible.", Color(0.52, 0.9, 0.58))
	else:
		var errors: Array = payload.get("errors", [])
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

# Apply flow: only executes when preview marked valid, then delegates to
# ApplyTemplatePlacementUseCase which performs authoritative revalidation.
func _place_selected_template() -> void:
	if _selected_template == null:
		_set_placement_message("Sélectionnez un template avant de poser.", Color(0.95, 0.5, 0.45))
		return
	if not _ghost_valid:
		_set_placement_message("Placement refusé: zone invalide.", Color(0.95, 0.5, 0.45))
		return

	var result := AppServices.apply_template_placement_use_case.execute(
		AppServices.session,
		_selected_template,
		_ghost_origin,
		_rotation_index,
		WORLD_BOUNDS
	)
	if not result.get("success", false):
		_set_placement_message(String(result.get("message", "Placement refusé.")), Color(0.95, 0.5, 0.45))
		return

	_renderer.render_full(AppServices.session.world_voxel_state)
	_refresh_assignment_ui()
	_update_status()
	_set_placement_message(String(result.get("message", "Placement réussi.")), Color(0.52, 0.9, 0.58))
	_update_ghost_preview()

func _sync_villager_logistics_visuals() -> void:
	var village := AppServices.session.village
	var active_ids := {}
	for villager in village.villagers:
		active_ids[villager.id] = true
		var actor := _villager_actor_nodes.get(villager.id, null)
		if actor == null or not is_instance_valid(actor):
			actor = _create_villager_actor()
			_villager_actor_nodes[villager.id] = actor
			_logistics_actors_root.add_child(actor)

		actor.position = Vector3(
			float(villager.current_cell.x) + 0.5,
			float(villager.current_cell.y) + 0.45,
			float(villager.current_cell.z) + 0.5
		)
		var crate: MeshInstance3D = actor.get_node("CarryCrate")
		crate.visible = villager.carry_units > 0
		if crate.visible:
			crate.modulate = _resource_color(villager.carry_resource)

	for villager_id in _villager_actor_nodes.keys():
		if active_ids.has(villager_id):
			continue
		var stale_actor: Node3D = _villager_actor_nodes[villager_id]
		if is_instance_valid(stale_actor):
			stale_actor.queue_free()
		_villager_actor_nodes.erase(villager_id)

func _create_villager_actor() -> Node3D:
	var actor := Node3D.new()
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.2
	capsule.height = 0.5
	body.mesh = capsule
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.89, 0.78, 0.63)
	body.material_override = body_material
	actor.add_child(body)

	var crate := MeshInstance3D.new()
	crate.name = "CarryCrate"
	var box := BoxMesh.new()
	box.size = Vector3(0.28, 0.28, 0.28)
	crate.mesh = box
	crate.position = Vector3(0.0, 0.45, 0.0)
	crate.visible = false
	actor.add_child(crate)
	return actor

func _resource_color(resource_id: StringName) -> Color:
	match resource_id:
		&"food":
			return Color(0.4, 0.84, 0.43)
		&"wood":
			return Color(0.59, 0.4, 0.25)
		&"materials":
			return Color(0.75, 0.75, 0.78)
		_:
			return Color(0.92, 0.92, 0.92)

func _set_placement_message(message: String, color: Color) -> void:
	_placement_label.text = message
	_placement_label.modulate = color
