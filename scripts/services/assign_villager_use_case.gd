# AssignVillagerUseCase
# -----------------------------------------------------------------------------
# Architecture role: Use Case (work assignment business action).
# Responsibilities:
# - Validates assignment request context and delegates mutation to
#   PopulationService.
# - Returns standardized result payload and debug coherence checks.
# Side effects:
# - Mutates canonical villager/building assignment fields.
# - Updates transient worker_assignments mirror through PopulationService.
extends RefCounted
class_name AssignVillagerUseCase

var _population: PopulationService

func setup(population: PopulationService) -> AssignVillagerUseCase:
	_population = population
	return self

# Executes villager-to-building assignment flow.
# Inputs: village aggregate, villager id, building instance id.
# Output: standardized success/failure dictionary.
# Error code semantics:
# - service_unavailable: missing dependency.
# - village_missing/building_missing: invalid context.
# - assign_failed: domain rejection (capacity, missing entities, etc.).
func execute(village: VillageState, villager_id: int, building_instance_id: StringName) -> Dictionary:
	if _population == null:
		return UseCaseResultFactory.failure(&"service_unavailable", "Service de population indisponible.")
	if village == null:
		return UseCaseResultFactory.failure(&"village_missing", "Village introuvable.")
	if building_instance_id == &"":
		return UseCaseResultFactory.failure(&"building_missing", "Bâtiment introuvable.")

	var assign_result := _population.assign_villager(village, villager_id, building_instance_id)
	if not assign_result.get("ok", false):
		var error_message := String(assign_result.get("error", "Affectation impossible."))
		return UseCaseResultFactory.failure(&"assign_failed", error_message)

	_validate_assignment_coherence(village, villager_id, building_instance_id)
	return UseCaseResultFactory.success(&"assigned", "Villageois %d affecté." % villager_id, {
		"villager_id": villager_id,
		"building_instance_id": building_instance_id,
	})

# Debug-only coherence guard ensuring canonical/transient assignment alignment.
func _validate_assignment_coherence(village: VillageState, villager_id: int, building_instance_id: StringName) -> void:
	if not OS.is_debug_build():
		return

	var villager := _find_villager(village.villagers, villager_id)
	var building := _find_building(village.placed_buildings, building_instance_id)
	if villager == null or building == null:
		push_warning("AssignVillagerUseCase: vérification impossible (entités introuvables).")
		return

	if villager.assigned_building_id != building_instance_id:
		push_warning("AssignVillagerUseCase: assigned_building_id incohérent après affectation.")
	if not building.assigned_worker_ids.has(villager_id):
		push_warning("AssignVillagerUseCase: index assigned_worker_ids incohérent après affectation.")

	var assignment_found := false
	for entry in village.worker_assignments:
		if int(entry.get("villager_id", -1)) != villager_id:
			continue
		if entry.get("building_instance_id", &"") == building_instance_id:
			assignment_found = true
			break
	if not assignment_found:
		push_warning("AssignVillagerUseCase: worker_assignments transitoire non synchronisé.")

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
