extends "res://tests/test_case.gd"

const Factory = preload("res://tests/helpers/test_data_factory.gd")

func run() -> void:
	test_evaluate_valid_and_invalid_paths()
	test_apply_success_updates_world_and_village_runtime()
	test_apply_rejects_invalid_placement()
	test_preview_apply_alignment_on_same_case()

func test_evaluate_valid_and_invalid_paths() -> void:
	var services := Factory.create_services()
	var session := Factory.create_session()
	var template := Factory.clone_house_template()

	var valid := services["evaluate"].execute(session, template, Vector3i(2, 0, 2), 0, Vector3i(12, 6, 12))
	assert_true(valid.get("success", false), "EvaluateTemplatePlacementUseCase doit accepter une zone vide et valide")
	assert_eq(valid.get("code", &""), &"placement_valid", "Evaluate doit retourner placement_valid")
	assert_not_empty(valid.get("payload", {}).get("block_instances", []), "Evaluate doit retourner des block_instances")

	Factory.add_single_block(session.world_voxel_state, Vector3i(2, 0, 2), &"stone")
	var invalid := services["evaluate"].execute(session, template, Vector3i(2, 0, 2), 0, Vector3i(12, 6, 12))
	assert_false(invalid.get("success", true), "EvaluateTemplatePlacementUseCase doit refuser une collision")
	assert_eq(invalid.get("code", &""), &"placement_invalid", "Evaluate doit retourner placement_invalid sur collision")
	assert_not_empty(invalid.get("payload", {}).get("errors", []), "Evaluate doit exposer la liste des erreurs")

func test_apply_success_updates_world_and_village_runtime() -> void:
	var services := Factory.create_services()
	var session := Factory.create_session()
	var template := Factory.clone_house_template()

	services["pathfinding"].configure(Rect3i(0, 0, 0, 20, 8, 20))
	var result := services["apply"].execute(session, template, Vector3i(3, 0, 3), 0, Vector3i(20, 8, 20))

	assert_true(result.get("success", false), "ApplyTemplatePlacementUseCase doit réussir sur une zone libre")
	assert_eq(session.village.placed_buildings.size(), 1, "Apply doit créer un BuildingInstance canonique")
	assert_true(session.world_voxel_state.cells.size() > 0, "Apply doit écrire des blocs dans world_voxel_state")
	assert_eq(session.village.placed_blocks.size(), session.world_voxel_state.cells.size(), "placed_blocks doit rester synchronisé avec world_voxel_state")
	assert_eq(int(result.get("payload", {}).get("spawned_villager_count", -1)), session.village.villagers.size(), "spawned_villager_count doit refléter les villageois créés")

func test_apply_rejects_invalid_placement() -> void:
	var services := Factory.create_services()
	var session := Factory.create_session()
	var template := Factory.clone_house_template()
	services["pathfinding"].configure(Rect3i(0, 0, 0, 20, 8, 20))

	Factory.add_single_block(session.world_voxel_state, Vector3i(3, 0, 3), &"stone")
	var result := services["apply"].execute(session, template, Vector3i(3, 0, 3), 0, Vector3i(20, 8, 20))

	assert_false(result.get("success", true), "ApplyTemplatePlacementUseCase doit refuser un placement invalide")
	assert_eq(result.get("code", &""), &"placement_invalid", "Apply doit retourner placement_invalid en cas de collision")
	assert_eq(session.village.placed_buildings.size(), 0, "Aucun building ne doit être ajouté sur un échec")

func test_preview_apply_alignment_on_same_case() -> void:
	var services := Factory.create_services()
	var session := Factory.create_session()
	var template := Factory.clone_house_template()
	services["pathfinding"].configure(Rect3i(0, 0, 0, 20, 8, 20))

	var evaluate_result := services["evaluate"].execute(session, template, Vector3i(4, 0, 4), 0, Vector3i(20, 8, 20))
	var apply_result := services["apply"].execute(session, template, Vector3i(4, 0, 4), 0, Vector3i(20, 8, 20))
	assert_eq(evaluate_result.get("success", false), apply_result.get("success", false), "Evaluate et Apply doivent rester alignés pour un même cas valide")

	var session_collision := Factory.create_session()
	Factory.add_single_block(session_collision.world_voxel_state, Vector3i(4, 0, 4), &"stone")
	var evaluate_collision := services["evaluate"].execute(session_collision, template, Vector3i(4, 0, 4), 0, Vector3i(20, 8, 20))
	var apply_collision := services["apply"].execute(session_collision, template, Vector3i(4, 0, 4), 0, Vector3i(20, 8, 20))
	assert_eq(evaluate_collision.get("success", true), apply_collision.get("success", true), "Evaluate et Apply doivent rester alignés pour un même cas invalide")
