extends Resource
class_name VillageState

@export var seed: int = 0
@export var placed_blocks: Dictionary = {}
@export var placed_buildings: Array[BuildingInstance] = []
@export var households: Array[Dictionary] = []
@export var worker_assignments: Array[Dictionary] = []
@export var resource_stocks: Dictionary = {
	"food": 0,
	"wood": 0,
	"materials": 0,
}
