# SessionRuntimeService
# -----------------------------------------------------------------------------
# Architecture role: Service (runtime bootstrap/reset/synchronization).
# Responsibilities:
# - Bootstraps world runtime canonical structures and dependent systems.
# - Resets template-builder runtime map.
# - Maintains compatibility transient mirrors (placed_blocks).
# - Runs debug coherence checks for canonical/transient alignment.
# Canonical vs transient:
# - Canonical world voxels live in GameSessionState.world_voxel_state.cells.
# - VillageState.placed_blocks is a transient compatibility mirror kept in sync.
# Why transients still exist:
# - Some legacy UI/runtime code paths still read village mirrors directly.
# - This service centralizes synchronization to prevent ad-hoc drift.
extends RefCounted
class_name SessionRuntimeService

var _world_generation: WorldGenerationService
var _pathfinding: GridPathfindingService
var _logistics: LogisticsService

func setup(
	world_generation: WorldGenerationService,
	pathfinding: GridPathfindingService,
	logistics: LogisticsService
) -> SessionRuntimeService:
	_world_generation = world_generation
	_pathfinding = pathfinding
	_logistics = logistics
	return self

# Initializes a playable world runtime from services and session containers.
# Side effects:
# - Recreates canonical terrain voxels.
# - Resets village runtime entities and transient aggregates.
# - Rebuilds pathfinding graph and resets logistics runtime.
func bootstrap_world_runtime(session: GameSessionState, map_width: int, map_depth: int, map_height: int) -> Dictionary:
	if not _validate_runtime_dependencies() or session == null:
		return _result(false, &"invalid_runtime", "Runtime world indisponible.")

	assert(session.village != null, "Session runtime: village manquant.")
	assert(session.world_voxel_state != null, "Session runtime: world voxel state manquant.")

	var village := session.village
	var world_state := session.world_voxel_state
	village.seed = Time.get_unix_time_from_system()
	world_state.cells = _world_generation.generate_height_map(map_width, map_depth, village.seed)
	_sync_transient_placed_blocks(village, world_state)

	village.placed_buildings.clear()
	village.villagers.clear()
	village.worker_assignments.clear()
	village.resource_stocks = {"food": 0, "wood": 0, "materials": 0}

	_pathfinding.configure(Rect3i(0, 0, 0, map_width, map_height, map_depth))
	_pathfinding.rebuild_navigation_graph(world_state, village.placed_buildings)
	_logistics.reset_runtime()

	_validate_runtime_coherence(session)
	return _result(true, &"ok", "Runtime monde initialisé.")

# Clears template-builder canonical voxel state for a fresh editing session.
func reset_template_builder_runtime(session: GameSessionState) -> Dictionary:
	if session == null or session.template_voxel_state == null:
		return _result(false, &"invalid_runtime", "Runtime template builder indisponible.")
	session.template_voxel_state.cells.clear()
	return _result(true, &"ok", "Runtime template builder réinitialisé.")

# Public sync entrypoint for compatibility transient blocks mirror.
func sync_transient_world_blocks(session: GameSessionState) -> void:
	if session == null or session.village == null or session.world_voxel_state == null:
		return
	_sync_transient_placed_blocks(session.village, session.world_voxel_state)
	_validate_runtime_coherence(session)

# Public debug helper to run runtime coherence checks on demand.
func validate_runtime_coherence(session: GameSessionState) -> void:
	_validate_runtime_coherence(session)

func _sync_transient_placed_blocks(village: VillageState, world_state: VoxelBuildState) -> void:
	# Compatibility bridge: placed_blocks is derived from canonical world_voxel_state.cells.
	village.placed_blocks = world_state.cells.duplicate(true)

func _validate_runtime_dependencies() -> bool:
	return _world_generation != null and _pathfinding != null and _logistics != null

func _validate_runtime_coherence(session: GameSessionState) -> void:
	if not OS.is_debug_build() or session == null:
		return
	if session.village == null or session.world_voxel_state == null:
		push_error("SessionRuntimeService: structures runtime manquantes.")
		return

	var village := session.village
	var world_cells: Dictionary = session.world_voxel_state.cells

	if village.placed_blocks.size() != world_cells.size():
		push_warning("SessionRuntimeService: placed_blocks transitoire désynchronisé de world_voxel_state.cells.")

	for villager in village.villagers:
		if villager.assigned_building_id == &"":
			continue
		var building := _find_building(village.placed_buildings, villager.assigned_building_id)
		if building == null or not building.assigned_worker_ids.has(villager.id):
			push_warning("SessionRuntimeService: index d'assignation incohérent pour villageois %d." % villager.id)

	var aggregated := {"food": 0, "wood": 0, "materials": 0}
	for building in village.placed_buildings:
		for key in aggregated.keys():
			aggregated[key] = int(aggregated[key]) + int(building.local_stocks.get(key, 0))
	if village.resource_stocks != aggregated:
		push_warning("SessionRuntimeService: resource_stocks transitoire n'est plus aligné avec les stocks locaux.")

func _find_building(buildings: Array[BuildingInstance], building_id: StringName) -> BuildingInstance:
	for building in buildings:
		if building.id == building_id:
			return building
	return null

func _result(success: bool, code: StringName, message: String, payload: Dictionary = {}) -> Dictionary:
	return {
		"success": success,
		"code": code,
		"message": message,
		"payload": payload,
	}
