# LogisticsService
# -----------------------------------------------------------------------------
# Architecture role: Service (runtime production + transport simulation).
# Responsibilities:
# - Produces resources from workered producer buildings.
# - Assigns transport jobs to villagers and advances movement over paths.
# - Resolves pickup/delivery and synchronizes global transient stock aggregate.
# Canonical vs transient:
# - Canonical per-building stocks: BuildingInstance.local_stocks.
# - Transient aggregate mirror: VillageState.resource_stocks (derived each tick).
extends RefCounted
class_name LogisticsService

const RESOURCE_FOOD := &"food"
const RESOURCE_WOOD := &"wood"
const RESOURCE_MATERIALS := &"materials"
const RESOURCE_KEYS := [RESOURCE_FOOD, RESOURCE_WOOD, RESOURCE_MATERIALS]

const PRODUCER_OUTPUT_BY_ARCHETYPE := {
	&"farm": RESOURCE_FOOD,
	&"scierie": RESOURCE_WOOD,
	&"sawmill": RESOURCE_WOOD,
	&"atelier": RESOURCE_MATERIALS,
	&"workshop": RESOURCE_MATERIALS,
}

const PRODUCE_INTERVAL_SEC := 2.0
const CRATE_UNITS := 4
const WALK_SPEED_CELLS_PER_SEC := 2.5
const HOUSE_TARGET_STOCK := 8

var _production_elapsed := 0.0
var _path_progress_by_villager: Dictionary = {}

# Clears internal simulation timers/caches when runtime resets.
func reset_runtime() -> void:
	_production_elapsed = 0.0
	_path_progress_by_villager.clear()

# Ensures stock dictionaries and initial villager anchor cells are initialized.
func initialize_village_logistics(village: VillageState, pathfinding: GridPathfindingService = null) -> void:
	if village == null:
		return

	for building in village.placed_buildings:
		_ensure_stock_dict(building.local_stocks)

	for villager in village.villagers:
		if villager.current_cell == Vector3i.ZERO:
			var home := _find_building(village.placed_buildings, villager.home_building_id)
			villager.current_cell = _building_anchor_cell(home, pathfinding, villager.current_cell)

# Advances one logistics simulation tick.
# Side effects:
# - Mutates villager jobs, positions, carried resources, and states.
# - Mutates building local stocks through production and deliveries.
# - Recomputes village.resource_stocks aggregate mirror.
func tick(village: VillageState, pathfinding: GridPathfindingService, delta: float) -> Dictionary:
	if village == null:
		return {"moves": 0, "deliveries": 0}

	initialize_village_logistics(village, pathfinding)
	_produce(village, delta)

	var deliveries := 0
	var moves := 0
	for villager in village.villagers:
		if villager.logistics_job.is_empty():
			_try_assign_job(village, villager, pathfinding)

		if _move_villager(villager, delta):
			moves += 1
		if _try_resolve_arrival(village, villager, pathfinding):
			deliveries += 1

	_sync_global_stocks(village)
	return {"moves": moves, "deliveries": deliveries}

# Producer loop: periodically injects resources into building local stocks.
func _produce(village: VillageState, delta: float) -> void:
	_production_elapsed += delta
	if _production_elapsed < PRODUCE_INTERVAL_SEC:
		return
	_production_elapsed -= PRODUCE_INTERVAL_SEC

	for building in village.placed_buildings:
		var resource: StringName = PRODUCER_OUTPUT_BY_ARCHETYPE.get(building.archetype_id, &"")
		if resource == &"":
			continue
		var workers := max(building.assigned_worker_ids.size(), 1)
		building.local_stocks[resource] = int(building.local_stocks.get(resource, 0)) + workers

# Assigns a logistics job to a villager if one is available.
func _try_assign_job(village: VillageState, villager: VillagerRuntimeData, pathfinding: GridPathfindingService) -> void:
	var job := _select_job(village)
	if job.is_empty():
		villager.state = VillagerRuntimeData.STATE_IDLE
		return

	villager.logistics_job = job
	villager.carry_resource = &""
	villager.carry_units = 0
	villager.state = VillagerRuntimeData.STATE_TRANSPORTING
	var source_cell := _building_anchor_cell(job.get("source"), pathfinding, villager.current_cell)
	_set_path(villager, pathfinding, source_cell)

# Job selection priority:
# 1) Producer -> Market replenishment.
# 2) Market -> House distribution toward target stock.
func _select_job(village: VillageState) -> Dictionary:
	var market := _first_building_by_archetype(village.placed_buildings, &"market")
	if market == null:
		return {}

	for building in village.placed_buildings:
		if building == market:
			continue
		var output: StringName = PRODUCER_OUTPUT_BY_ARCHETYPE.get(building.archetype_id, &"")
		if output == &"":
			continue
		var available := int(building.local_stocks.get(output, 0))
		if available <= 0:
			continue
		return {
			"phase": "to_source",
			"resource": output,
			"source": building,
			"destination": market,
		}

	for house in village.placed_buildings:
		if house.archetype_id != &"house":
			continue
		for resource in RESOURCE_KEYS:
			var available_market := int(market.local_stocks.get(resource, 0))
			if available_market <= 0:
				continue
			var house_stock := int(house.local_stocks.get(resource, 0))
			if house_stock >= HOUSE_TARGET_STOCK:
				continue
			return {
				"phase": "to_source",
				"resource": resource,
				"source": market,
				"destination": house,
			}

	return {}

func _move_villager(villager: VillagerRuntimeData, delta: float) -> bool:
	if villager.logistics_job.is_empty():
		return false

	if villager.path_cells.is_empty():
		return false

	if villager.current_cell == villager.path_cells[0]:
		villager.path_cells.remove_at(0)
		if villager.path_cells.is_empty():
			return false

	var villager_key := villager.id
	var progress := float(_path_progress_by_villager.get(villager_key, 0.0)) + (WALK_SPEED_CELLS_PER_SEC * delta)
	if progress < 1.0:
		_path_progress_by_villager[villager_key] = progress
		return false

	_path_progress_by_villager[villager_key] = progress - 1.0
	villager.current_cell = villager.path_cells[0]
	villager.path_cells.remove_at(0)
	return true

func _try_resolve_arrival(village: VillageState, villager: VillagerRuntimeData, pathfinding: GridPathfindingService) -> bool:
	if villager.logistics_job.is_empty() or not villager.path_cells.is_empty():
		return false

	var phase := String(villager.logistics_job.get("phase", ""))
	var source: BuildingInstance = villager.logistics_job.get("source", null)
	var destination: BuildingInstance = villager.logistics_job.get("destination", null)
	var resource: StringName = villager.logistics_job.get("resource", &"")
	if source == null or destination == null or resource == &"":
		_clear_villager_job(villager)
		return false

	if phase == "to_source":
		var available := int(source.local_stocks.get(resource, 0))
		if available <= 0:
			_clear_villager_job(villager)
			return false

		var picked_units := min(CRATE_UNITS, available)
		source.local_stocks[resource] = available - picked_units
		villager.carry_resource = resource
		villager.carry_units = picked_units
		villager.logistics_job["phase"] = "to_destination"
		var destination_cell := _building_anchor_cell(destination, pathfinding, villager.current_cell)
		_set_path(villager, pathfinding, destination_cell)
		return false

	if phase == "to_destination":
		destination.local_stocks[resource] = int(destination.local_stocks.get(resource, 0)) + villager.carry_units
		_clear_villager_job(villager)
		return true

	_clear_villager_job(villager)
	return false

func _set_path(villager: VillagerRuntimeData, pathfinding: GridPathfindingService, to_cell: Vector3i) -> void:
	if pathfinding == null:
		villager.path_cells = []
		return
	var path := pathfinding.get_id_path(villager.current_cell, to_cell)
	if path.is_empty():
		villager.path_cells = []
		return
	villager.path_cells = path

func _clear_villager_job(villager: VillagerRuntimeData) -> void:
	villager.logistics_job = {}
	villager.path_cells.clear()
	villager.carry_resource = &""
	villager.carry_units = 0
	villager.state = VillagerRuntimeData.STATE_IDLE
	_path_progress_by_villager.erase(villager.id)

# Rebuilds transient global stocks from canonical per-building local stocks.
func _sync_global_stocks(village: VillageState) -> void:
	var totals := {
		"food": 0,
		"wood": 0,
		"materials": 0,
	}
	for building in village.placed_buildings:
		_ensure_stock_dict(building.local_stocks)
		for key in totals.keys():
			totals[key] = int(totals[key]) + int(building.local_stocks.get(key, 0))
	village.resource_stocks = totals

func _first_building_by_archetype(buildings: Array[BuildingInstance], archetype_id: StringName) -> BuildingInstance:
	for building in buildings:
		if building.archetype_id == archetype_id:
			return building
	return null

func _find_building(buildings: Array[BuildingInstance], building_id: StringName) -> BuildingInstance:
	for building in buildings:
		if building.id == building_id:
			return building
	return null

func _building_anchor_cell(building: BuildingInstance, pathfinding: GridPathfindingService, from_cell: Vector3i) -> Vector3i:
	if building == null:
		return Vector3i.ZERO
	if pathfinding != null:
		return pathfinding.get_accessible_cell_for_building(building, from_cell)
	if not building.block_instances.is_empty():
		return building.block_instances[0].get("cell", building.origin_cell)
	return building.origin_cell

func _ensure_stock_dict(stocks: Dictionary) -> void:
	for key in RESOURCE_KEYS:
		if not stocks.has(key):
			stocks[key] = 0
