# AppServices
# -----------------------------------------------------------------------------
# Architecture role: Core System (composition root / service locator).
# Responsibilities:
# - Instantiates and wires runtime services + use cases once.
# - Owns current GameSessionState and provides session reset entrypoint.
# - Seeds default template catalog into each new session.
extends Node
class_name AppServices

const SAMPLE_TEMPLATE: BuildingTemplateDefinition = preload("res://data/definitions/templates/sample_house_template.tres")
const SAMPLE_FARM_TEMPLATE: BuildingTemplateDefinition = preload("res://data/definitions/templates/sample_farm_template.tres")
const SAMPLE_MARKET_TEMPLATE: BuildingTemplateDefinition = preload("res://data/definitions/templates/sample_market_template.tres")

var world_generation: WorldGenerationService
var pathfinding: GridPathfindingService
var population: PopulationService
var logistics: LogisticsService
var template_validation: TemplateValidationService
var block_placement: BlockPlacementService
var template_placement: TemplatePlacementService
var session_runtime: SessionRuntimeService
var assign_villager_use_case: AssignVillagerUseCase
var evaluate_template_placement_use_case: EvaluateTemplatePlacementUseCase
var apply_template_placement_use_case: ApplyTemplatePlacementUseCase

var session: GameSessionState

# Initializes dependency graph used by controllers.
func _ready() -> void:
	world_generation = WorldGenerationService.new()
	pathfinding = GridPathfindingService.new()
	population = PopulationService.new()
	logistics = LogisticsService.new()
	template_validation = TemplateValidationService.new()
	block_placement = BlockPlacementService.new()
	template_placement = TemplatePlacementService.new()
	session_runtime = SessionRuntimeService.new().setup(world_generation, pathfinding, logistics)
	assign_villager_use_case = AssignVillagerUseCase.new().setup(population)
	evaluate_template_placement_use_case = EvaluateTemplatePlacementUseCase.new().setup(template_placement)
	apply_template_placement_use_case = ApplyTemplatePlacementUseCase.new().setup(
		population,
		evaluate_template_placement_use_case,
		template_placement,
		block_placement,
		pathfinding,
		logistics,
		session_runtime
	)
	session = _build_default_session()

# Recreates session runtime containers while preserving service singletons.
func reset_session() -> void:
	session = _build_default_session()

# Builds a new default session with duplicated starter templates.
func _build_default_session() -> GameSessionState:
	var new_session := GameSessionState.new()
	new_session.template_catalog.templates = [
		SAMPLE_TEMPLATE.duplicate(true),
		SAMPLE_FARM_TEMPLATE.duplicate(true),
		SAMPLE_MARKET_TEMPLATE.duplicate(true),
	]
	return new_session
