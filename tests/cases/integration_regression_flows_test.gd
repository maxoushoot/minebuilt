extends "res://tests/test_case.gd"

const Factory = preload("res://tests/helpers/test_data_factory.gd")

func run() -> void:
	test_apply_then_assign_updates_expected_runtime_state()
	test_invalid_and_valid_placement_regression_guards()
	test_repeated_house_placement_after_reset_does_not_duplicate_existing_villagers()

func test_apply_then_assign_updates_expected_runtime_state() -> void:
	var services := Factory.create_services()
	var session := Factory.create_session()
	services["pathfinding"].configure(Rect3i(0, 0, 0, 20, 8, 20))

	var house_result := services["apply"].execute(session, Factory.clone_house_template(), Vector3i(2, 0, 2), 0, Vector3i(20, 8, 20))
	var farm_result := services["apply"].execute(session, Factory.clone_farm_template(), Vector3i(8, 0, 8), 0, Vector3i(20, 8, 20))
	assert_true(house_result.get("success", false), "Placement maison doit réussir")
	assert_true(farm_result.get("success", false), "Placement ferme doit réussir")
	assert_true(session.village.villagers.size() >= 2, "La maison doit avoir généré au moins deux villageois")

	var villager_id := session.village.villagers[0].id
	var farm_id: StringName = farm_result.get("payload", {}).get("building_instance_id", &"")
	var assign_result := services["assign"].execute(session.village, villager_id, farm_id)
	assert_true(assign_result.get("success", false), "L'affectation doit rester fonctionnelle après Sprint B/C")
	assert_true(session.village.worker_assignments.size() >= 1, "worker_assignments doit être alimenté après affectation")

func test_invalid_and_valid_placement_regression_guards() -> void:
	var services := Factory.create_services()
	services["pathfinding"].configure(Rect3i(0, 0, 0, 20, 8, 20))

	var invalid_session := Factory.create_session()
	Factory.add_single_block(invalid_session.world_voxel_state, Vector3i(4, 0, 4), &"stone")
	var invalid := services["apply"].execute(invalid_session, Factory.clone_house_template(), Vector3i(4, 0, 4), 0, Vector3i(20, 8, 20))
	assert_false(invalid.get("success", true), "Régression: un placement invalide doit rester rejeté")

	var valid_session := Factory.create_session()
	var valid := services["apply"].execute(valid_session, Factory.clone_house_template(), Vector3i(5, 0, 5), 0, Vector3i(20, 8, 20))
	assert_true(valid.get("success", false), "Régression: un placement valide doit rester accepté")

func test_repeated_house_placement_after_reset_does_not_duplicate_existing_villagers() -> void:
	var services := Factory.create_services()
	var session := Factory.create_session()
	services["pathfinding"].configure(Rect3i(0, 0, 0, 20, 8, 20))

	var first := services["apply"].execute(session, Factory.clone_house_template(), Vector3i(1, 0, 1), 0, Vector3i(20, 8, 20))
	assert_true(first.get("success", false), "Premier placement maison valide")
	var first_ids: Dictionary = {}
	for villager in session.village.villagers:
		first_ids[villager.id] = true
	assert_not_empty(first_ids, "Le premier placement doit générer des villageois")

	services["session_runtime"].bootstrap_world_runtime(session, 20, 20, 8)
	services["pathfinding"].configure(Rect3i(0, 0, 0, 20, 8, 20))
	var second := services["apply"].execute(session, Factory.clone_house_template(), Vector3i(1, 0, 1), 0, Vector3i(20, 8, 20))
	assert_true(second.get("success", false), "Second placement maison valide après reset")

	var second_ids: Dictionary = {}
	for villager in session.village.villagers:
		second_ids[villager.id] = true
	assert_eq(second_ids.size(), session.village.villagers.size(), "Aucun doublon d'identifiant villageois après reset + placement")
	assert_true(session.village.placed_blocks.size() == session.world_voxel_state.cells.size(), "Aucun bloc transitoire obsolète après reset + placement")
