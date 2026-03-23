extends "res://tests/test_case.gd"

const Factory = preload("res://tests/helpers/test_data_factory.gd")

func run() -> void:
	test_bootstrap_resets_runtime_and_compatibility_structures()
	test_sync_transient_world_blocks_mirrors_canonical_state()
	test_reset_template_builder_runtime_clears_cells()
	test_repeated_bootstrap_does_not_leave_stale_data()

func test_bootstrap_resets_runtime_and_compatibility_structures() -> void:
	var services := Factory.create_services()
	var session := Factory.create_session()
	var village := session.village

	village.placed_buildings = [Factory.make_building(&"legacy", &"farm", Vector3i.ZERO, [Vector3i.ZERO])]
	village.worker_assignments = [{"villager_id": 1, "building_instance_id": &"legacy"}]
	village.villagers = [Factory.make_villager(1, &"legacy")]
	village.resource_stocks = {"food": 5, "wood": 1, "materials": 9}

	var result := services["session_runtime"].bootstrap_world_runtime(session, 8, 8, 4)
	assert_true(result.get("success", false), "bootstrap_world_runtime doit réussir avec des services valides")
	assert_eq(village.placed_buildings.size(), 0, "bootstrap_world_runtime doit vider placed_buildings")
	assert_eq(village.worker_assignments.size(), 0, "bootstrap_world_runtime doit vider worker_assignments")
	assert_eq(village.villagers.size(), 0, "bootstrap_world_runtime doit vider villagers")
	assert_eq(village.resource_stocks, {"food": 0, "wood": 0, "materials": 0}, "bootstrap_world_runtime doit réinitialiser resource_stocks")
	assert_eq(village.placed_blocks.size(), session.world_voxel_state.cells.size(), "placed_blocks doit refléter world_voxel_state après bootstrap")

func test_sync_transient_world_blocks_mirrors_canonical_state() -> void:
	var services := Factory.create_services()
	var session := Factory.create_session()
	Factory.add_single_block(session.world_voxel_state, Vector3i(1, 0, 1), &"stone")
	Factory.add_single_block(session.world_voxel_state, Vector3i(2, 0, 1), &"grass")

	services["session_runtime"].sync_transient_world_blocks(session)
	assert_eq(session.village.placed_blocks.size(), 2, "sync_transient_world_blocks doit copier toutes les cellules")
	assert_true(session.village.placed_blocks.has(Vector3i(1, 0, 1)), "placed_blocks doit contenir les cellules canoniques")

func test_reset_template_builder_runtime_clears_cells() -> void:
	var services := Factory.create_services()
	var session := Factory.create_session()
	session.template_voxel_state.cells[Vector3i(0, 0, 0)] = {"block_id": &"grass", "rotation": 0}

	var result := services["session_runtime"].reset_template_builder_runtime(session)
	assert_true(result.get("success", false), "reset_template_builder_runtime doit réussir")
	assert_eq(session.template_voxel_state.cells.size(), 0, "reset_template_builder_runtime doit vider les cellules")

func test_repeated_bootstrap_does_not_leave_stale_data() -> void:
	var services := Factory.create_services()
	var session := Factory.create_session()
	var first := services["session_runtime"].bootstrap_world_runtime(session, 10, 10, 5)
	assert_true(first.get("success", false), "Premier bootstrap valide")

	session.village.placed_blocks[Vector3i(99, 99, 99)] = {"block_id": &"ghost", "rotation": 0}
	var second := services["session_runtime"].bootstrap_world_runtime(session, 10, 10, 5)
	assert_true(second.get("success", false), "Second bootstrap valide")
	assert_false(session.village.placed_blocks.has(Vector3i(99, 99, 99)), "Un second bootstrap doit écraser les données transitoires obsolètes")
