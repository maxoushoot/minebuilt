extends RefCounted
class_name TestDataFactory

const SAMPLE_HOUSE: BuildingTemplateDefinition = preload("res://data/definitions/templates/sample_house_template.tres")
const SAMPLE_FARM: BuildingTemplateDefinition = preload("res://data/definitions/templates/sample_farm_template.tres")

static func create_session() -> GameSessionState:
	var session := GameSessionState.new()
	session.village = VillageState.new()
	session.world_voxel_state = VoxelBuildState.new()
	session.template_voxel_state = VoxelBuildState.new()
	return session

static func create_services() -> Dictionary:
	var world_generation := WorldGenerationService.new()
	var pathfinding := GridPathfindingService.new()
	var logistics := LogisticsService.new()
	var population := PopulationService.new()
	var template_placement := TemplatePlacementService.new()
	var block_placement := BlockPlacementService.new()
	var session_runtime := SessionRuntimeService.new().setup(world_generation, pathfinding, logistics)
	var evaluate := EvaluateTemplatePlacementUseCase.new().setup(template_placement)
	var apply := ApplyTemplatePlacementUseCase.new().setup(
		population,
		evaluate,
		template_placement,
		block_placement,
		pathfinding,
		logistics,
		session_runtime
	)
	var assign := AssignVillagerUseCase.new().setup(population)
	return {
		"world_generation": world_generation,
		"pathfinding": pathfinding,
		"logistics": logistics,
		"population": population,
		"template_placement": template_placement,
		"block_placement": block_placement,
		"session_runtime": session_runtime,
		"evaluate": evaluate,
		"apply": apply,
		"assign": assign,
	}

static func clone_house_template() -> BuildingTemplateDefinition:
	return SAMPLE_HOUSE.duplicate(true)

static func clone_farm_template() -> BuildingTemplateDefinition:
	return SAMPLE_FARM.duplicate(true)

static func add_single_block(world_state: VoxelBuildState, cell: Vector3i, block_id: StringName = &"grass") -> void:
	world_state.cells[cell] = {"block_id": block_id, "rotation": 0}

static func make_building(id: StringName, archetype: StringName, origin: Vector3i, block_cells: Array[Vector3i]) -> BuildingInstance:
	var building := BuildingInstance.new()
	building.id = id
	building.archetype_id = archetype
	building.origin_cell = origin
	for cell in block_cells:
		building.block_instances.append({"cell": cell, "block_id": &"grass", "rotation": 0})
	building.worker_capacity = PopulationService.new().worker_capacity_for_building(building)
	return building

static func make_villager(villager_id: int, home_id: StringName) -> VillagerRuntimeData:
	var villager := VillagerRuntimeData.new()
	villager.id = villager_id
	villager.display_name = "Villageois %03d" % villager_id
	villager.home_building_id = home_id
	villager.assigned_building_id = &""
	villager.state = VillagerRuntimeData.STATE_IDLE
	return villager
