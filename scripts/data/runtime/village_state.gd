extends Resource
class_name VillageState

@export var seed: int = 0
# TRANSIENT (compat): derived mirror of GameSessionState.world_voxel_state.cells.
@export var placed_blocks: Dictionary = {}
# Canonical source of truth for placed buildings in village runtime.
@export var placed_buildings: Array[BuildingInstance] = []
@export var households: Array[Dictionary] = []
# TRANSIENT (compat): derived from villagers[].assigned_building_id.
@export var worker_assignments: Array[Dictionary] = []
# Canonical source of truth for villager runtime data.
@export var villagers: Array[VillagerRuntimeData] = []
# TRANSIENT aggregate: derived from BuildingInstance.local_stocks.
@export var resource_stocks: Dictionary = {
	"food": 0,
	"wood": 0,
	"materials": 0,
}
