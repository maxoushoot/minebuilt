extends RefCounted
class_name GridPathfindingService

const DEFAULT_MOVE_COST := 1.0
const ROAD_MOVE_COST := 0.45
const ROAD_BLOCK_IDS := {
	&"road": true,
	&"path": true,
	&"stone_path": true,
	&"stone_road": true,
	&"paved_road": true,
}
const WALKABLE_BUILDING_ARCHETYPES := {
	&"road": true,
	&"path": true,
	&"street": true,
	&"plaza": true,
	&"bridge": true,
}

var _astar := AStarGrid3D.new()
var _bounds := Rect3i()
var _walkable_by_cell: Dictionary = {}
var _cost_by_cell: Dictionary = {}

func configure(bounds: Rect3i) -> void:
	_bounds = bounds
	_astar.region = bounds
	_astar.cell_size = Vector3.ONE
	_astar.diagonal_mode = AStarGrid3D.DIAGONAL_MODE_NEVER
	_astar.update()
	_walkable_by_cell.clear()
	_cost_by_cell.clear()

func rebuild_navigation_graph(world_state: VoxelBuildState, placed_buildings: Array[BuildingInstance]) -> void:
	var blocked_cells := _collect_blocked_building_cells(placed_buildings)
	var road_cells := _collect_road_cells(world_state, placed_buildings)
	for x in range(_bounds.position.x, _bounds.end.x):
		for y in range(_bounds.position.y, _bounds.end.y):
			for z in range(_bounds.position.z, _bounds.end.z):
				_recompute_cell(Vector3i(x, y, z), world_state, blocked_cells, road_cells)

func apply_local_map_update(changed_cells: Array[Vector3i], world_state: VoxelBuildState, placed_buildings: Array[BuildingInstance]) -> void:
	if changed_cells.is_empty():
		return
	var blocked_cells := _collect_blocked_building_cells(placed_buildings)
	var road_cells := _collect_road_cells(world_state, placed_buildings)
	var impacted := _expanded_local_cells(changed_cells)
	for cell in impacted:
		_recompute_cell(cell, world_state, blocked_cells, road_cells)

func is_cell_walkable(cell: Vector3i) -> bool:
	return bool(_walkable_by_cell.get(cell, false))

func get_accessible_cell_for_building(building: BuildingInstance, from_cell: Vector3i) -> Vector3i:
	if building == null:
		return from_cell

	var candidates: Array[Vector3i] = []
	for block in building.block_instances:
		var footprint: Vector3i = block.get("cell", building.origin_cell)
		if is_cell_walkable(footprint):
			candidates.append(footprint)

		for offset in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]:
			var neighbor := footprint + offset
			if is_cell_walkable(neighbor):
				candidates.append(neighbor)

	if candidates.is_empty():
		return building.origin_cell

	var best_cell := candidates[0]
	var best_path_len := INF
	for candidate in candidates:
		var candidate_path := get_id_path(from_cell, candidate)
		if candidate_path.is_empty():
			continue
		var path_len := candidate_path.size()
		if path_len < best_path_len:
			best_path_len = path_len
			best_cell = candidate

	return best_cell

func get_id_path(from_cell: Vector3i, to_cell: Vector3i) -> Array[Vector3i]:
	if not _astar.is_in_boundsv(from_cell) or not _astar.is_in_boundsv(to_cell):
		return []
	return _astar.get_id_path(from_cell, to_cell)

func _collect_blocked_building_cells(placed_buildings: Array[BuildingInstance]) -> Dictionary:
	var blocked := {}
	for building in placed_buildings:
		if WALKABLE_BUILDING_ARCHETYPES.has(building.archetype_id):
			continue
		for block in building.block_instances:
			var cell: Vector3i = block.get("cell", building.origin_cell)
			blocked[cell] = true
	return blocked

func _collect_road_cells(world_state: VoxelBuildState, placed_buildings: Array[BuildingInstance]) -> Dictionary:
	var road_cells := {}
	if world_state != null:
		for cell in world_state.cells.keys():
			var block_data: Dictionary = world_state.cells[cell]
			var block_id: StringName = block_data.get("block_id", &"")
			if ROAD_BLOCK_IDS.has(block_id):
				road_cells[cell] = true

	for building in placed_buildings:
		if not WALKABLE_BUILDING_ARCHETYPES.has(building.archetype_id):
			continue
		for block in building.block_instances:
			var cell: Vector3i = block.get("cell", building.origin_cell)
			road_cells[cell] = true
	return road_cells

func _expanded_local_cells(changed_cells: Array[Vector3i]) -> Array[Vector3i]:
	var impacted_lookup := {}
	for changed in changed_cells:
		for dy in [-1, 0, 1]:
			for offset in [Vector3i.ZERO, Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]:
				var expanded := changed + offset + Vector3i(0, dy, 0)
				if _astar.is_in_boundsv(expanded):
					impacted_lookup[expanded] = true
	return impacted_lookup.keys()

func _recompute_cell(cell: Vector3i, world_state: VoxelBuildState, blocked_cells: Dictionary, road_cells: Dictionary) -> void:
	if not _astar.is_in_boundsv(cell):
		return

	var exists := world_state != null and world_state.cells.has(cell)
	var walkable := exists and not blocked_cells.has(cell)
	var cost := ROAD_MOVE_COST if road_cells.has(cell) else DEFAULT_MOVE_COST
	_walkable_by_cell[cell] = walkable
	_cost_by_cell[cell] = cost
	_astar.set_point_solid(cell, not walkable)
	_astar.set_point_weight_scale(cell, cost)
