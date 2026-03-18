extends Node
class_name AppServices

var world_generation: WorldGenerationService
var pathfinding: GridPathfindingService
var population: PopulationService
var logistics: LogisticsService
var template_validation: TemplateValidationService

var session: GameSessionState

func _ready() -> void:
	world_generation = WorldGenerationService.new()
	pathfinding = GridPathfindingService.new()
	population = PopulationService.new()
	logistics = LogisticsService.new()
	template_validation = TemplateValidationService.new()
	session = GameSessionState.new()

func reset_session() -> void:
	session = GameSessionState.new()
