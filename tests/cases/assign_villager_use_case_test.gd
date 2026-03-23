extends "res://tests/test_case.gd"

const Factory = preload("res://tests/helpers/test_data_factory.gd")

func run() -> void:
	test_assign_success_updates_canonical_and_transient()
	test_assign_failure_when_capacity_full()
	test_assign_failure_when_use_case_not_setup()

func test_assign_success_updates_canonical_and_transient() -> void:
	var services := Factory.create_services()
	var session := Factory.create_session()
	var village := session.village

	var home := Factory.make_building(&"home_1", &"house", Vector3i(0, 0, 0), [Vector3i(0, 0, 0)])
	var farm := Factory.make_building(&"farm_1", &"farm", Vector3i(2, 0, 2), [Vector3i(2, 0, 2)])
	village.placed_buildings = [home, farm]

	var villager := Factory.make_villager(1, home.id)
	village.villagers = [villager]

	var result := services["assign"].execute(village, 1, farm.id)
	assert_true(result.get("success", false), "AssignVillagerUseCase doit réussir sur un cas valide")
	assert_eq(villager.assigned_building_id, farm.id, "Le villageois doit pointer vers le bâtiment cible")
	assert_true(farm.assigned_worker_ids.has(1), "Le bâtiment doit référencer le villageois")
	assert_eq(village.worker_assignments.size(), 1, "Le miroir worker_assignments doit être mis à jour")
	assert_eq(village.worker_assignments[0].get("building_instance_id", &""), farm.id, "worker_assignments doit contenir le building_id")

func test_assign_failure_when_capacity_full() -> void:
	var services := Factory.create_services()
	var session := Factory.create_session()
	var village := session.village

	var home := Factory.make_building(&"home_2", &"house", Vector3i(0, 0, 0), [Vector3i(0, 0, 0)])
	var school := Factory.make_building(&"school_1", &"school", Vector3i(1, 0, 1), [Vector3i(1, 0, 1)])
	school.worker_capacity = 1
	school.assigned_worker_ids = [99]
	village.placed_buildings = [home, school]
	village.villagers = [Factory.make_villager(2, home.id)]

	var result := services["assign"].execute(village, 2, school.id)
	assert_false(result.get("success", true), "AssignVillagerUseCase doit échouer quand la capacité est atteinte")
	assert_eq(result.get("code", &""), &"assign_failed", "Le code erreur doit être normalisé")
	assert_eq(village.villagers[0].assigned_building_id, &"", "Le villageois doit rester non affecté")

func test_assign_failure_when_use_case_not_setup() -> void:
	var use_case := AssignVillagerUseCase.new()
	var village := VillageState.new()
	var result := use_case.execute(village, 1, &"farm")
	assert_false(result.get("success", true), "AssignVillagerUseCase doit échouer sans setup")
	assert_eq(result.get("code", &""), &"service_unavailable", "Le code service_unavailable doit être retourné")
