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

var session: GameSessionState

func _ready() -> void:
	world_generation = WorldGenerationService.new()
	pathfinding = GridPathfindingService.new()
	population = PopulationService.new()
	logistics = LogisticsService.new()
	template_validation = TemplateValidationService.new()
	block_placement = BlockPlacementService.new()
	template_placement = TemplatePlacementService.new()
	session = _build_default_session()

func reset_session() -> void:
	session = _build_default_session()

func _build_default_session() -> GameSessionState:
	var new_session := GameSessionState.new()
	new_session.template_catalog.templates = [
		SAMPLE_TEMPLATE.duplicate(true),
		SAMPLE_FARM_TEMPLATE.duplicate(true),
		SAMPLE_MARKET_TEMPLATE.duplicate(true),
	]
	return new_session
