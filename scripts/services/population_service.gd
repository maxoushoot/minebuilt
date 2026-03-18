extends RefCounted
class_name PopulationService

const HOUSE_MIN_RESIDENTS := 2
const HOUSE_MAX_RESIDENTS := 4

const WORKER_CAPACITY_BY_ARCHETYPE := {
	&"farm": 3,
	&"market": 3,
	&"school": 2,
	&"townhall": 2,
}

func housing_capacity_from_home_count(home_count: int) -> int:
	return home_count * HOUSE_MIN_RESIDENTS

func worker_capacity_for_archetype(archetype_id: StringName) -> int:
	return int(WORKER_CAPACITY_BY_ARCHETYPE.get(archetype_id, 0))

func worker_capacity_for_building(building: BuildingInstance) -> int:
	if building == null:
		return 0
	return worker_capacity_for_archetype(building.archetype_id)

func should_spawn_villagers_from_house(building: BuildingInstance) -> bool:
	if building == null:
		return false
	if building.archetype_id != &"house":
		return false
	for entry in building.object_instances:
		var object_id: StringName = entry.get("object_id", &"")
		if String(object_id).begins_with("bed"):
			return true
	return false

func spawn_villagers_for_house(building: BuildingInstance, existing_villagers: Array[VillagerRuntimeData]) -> Array[VillagerRuntimeData]:
	if not should_spawn_villagers_from_house(building):
		return []

	var next_id := _next_villager_id(existing_villagers)
	var spawned: Array[VillagerRuntimeData] = []
	var resident_count := _house_resident_count(building.id)
	for i in range(resident_count):
		var villager := VillagerRuntimeData.new()
		villager.id = next_id + i
		villager.display_name = "Villageois %03d" % villager.id
		villager.home_building_id = building.id
		villager.assigned_building_id = &""
		villager.state = VillagerRuntimeData.STATE_IDLE
		spawned.append(villager)
	return spawned

func assign_villager(village: VillageState, villager_id: int, building_instance_id: StringName) -> Dictionary:
	if village == null:
		return {"ok": false, "error": "Village introuvable."}

	var villager := _find_villager(village.villagers, villager_id)
	if villager == null:
		return {"ok": false, "error": "Villageois introuvable."}

	var building := _find_building(village.placed_buildings, building_instance_id)
	if building == null:
		return {"ok": false, "error": "Bâtiment introuvable."}

	var capacity := max(building.worker_capacity, worker_capacity_for_building(building))
	building.worker_capacity = capacity
	if capacity <= 0:
		return {"ok": false, "error": "Ce bâtiment n'accepte pas de travailleurs."}

	if villager.assigned_building_id != &"":
		if villager.assigned_building_id == building.id:
			return {"ok": false, "error": "Ce villageois est déjà affecté ici."}
		_unassign_from_current_building(village, villager)

	if building.assigned_worker_ids.size() >= capacity:
		return {"ok": false, "error": "Capacité de travailleurs atteinte."}

	building.assigned_worker_ids.append(villager.id)
	villager.assigned_building_id = building.id
	villager.state = VillagerRuntimeData.STATE_GOING_TO_WORK
	_sync_worker_assignments(village)
	return {"ok": true}

func get_population_stats(village: VillageState) -> Dictionary:
	if village == null:
		return {"total": 0, "assigned": 0, "free": 0}

	var total := village.villagers.size()
	var assigned := 0
	for villager in village.villagers:
		if villager.assigned_building_id != &"":
			assigned += 1
	return {
		"total": total,
		"assigned": assigned,
		"free": max(total - assigned, 0),
	}

func _next_villager_id(existing_villagers: Array[VillagerRuntimeData]) -> int:
	var max_id := 0
	for villager in existing_villagers:
		max_id = max(max_id, villager.id)
	return max_id + 1

func _house_resident_count(house_id: StringName) -> int:
	var hash_value := int(abs(String(house_id).hash()))
	return HOUSE_MIN_RESIDENTS + (hash_value % (HOUSE_MAX_RESIDENTS - HOUSE_MIN_RESIDENTS + 1))

func _find_villager(villagers: Array[VillagerRuntimeData], villager_id: int) -> VillagerRuntimeData:
	for villager in villagers:
		if villager.id == villager_id:
			return villager
	return null

func _find_building(buildings: Array[BuildingInstance], building_id: StringName) -> BuildingInstance:
	for building in buildings:
		if building.id == building_id:
			return building
	return null

func _unassign_from_current_building(village: VillageState, villager: VillagerRuntimeData) -> void:
	for building in village.placed_buildings:
		if building.id == villager.assigned_building_id:
			building.assigned_worker_ids.erase(villager.id)
			break
	villager.assigned_building_id = &""
	villager.state = VillagerRuntimeData.STATE_IDLE

func _sync_worker_assignments(village: VillageState) -> void:
	var assignments: Array[Dictionary] = []
	for villager in village.villagers:
		if villager.assigned_building_id == &"":
			continue
		assignments.append({
			"villager_id": villager.id,
			"building_instance_id": villager.assigned_building_id,
		})
	village.worker_assignments = assignments
