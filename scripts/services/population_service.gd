extends RefCounted
class_name PopulationService

func housing_capacity_from_home_count(home_count: int) -> int:
	# V1 rule: each house supports 2..4 villagers. Use min capacity for deterministic planning.
	return home_count * 2

func assign_worker(villager_id: int, building_instance_id: int, assignments: Array[Dictionary]) -> Array[Dictionary]:
	var next := assignments.duplicate(true)
	next.append({
		"villager_id": villager_id,
		"building_instance_id": building_instance_id,
	})
	return next
