# BuildingInstance
# -----------------------------------------------------------------------------
# Architecture role: Runtime Data (canonical per-building entity).
# Responsibilities:
# - Represents one placed building instance in world runtime.
# - Stores transformed footprint/object placements and worker assignment slots.
# - Stores per-building local stocks used by logistics simulation.
# Invariants:
# - id is unique per placed building.
# - block_instances/object_instances are world-space transformed entries.
# - assigned_worker_ids size should stay <= worker_capacity.
extends Resource
class_name BuildingInstance

@export var id: StringName
@export var template_id: StringName
@export var template_name: String = ""
@export var archetype_id: StringName = &""
@export var worker_capacity: int = 0
@export var assigned_worker_ids: Array[int] = []
@export var origin_cell: Vector3i = Vector3i.ZERO
@export var rotation: int = 0
@export var block_instances: Array[Dictionary] = []
@export var object_instances: Array[Dictionary] = []
# Canonical source of truth for per-building stocks.
@export var local_stocks: Dictionary = {
	"food": 0,
	"wood": 0,
	"materials": 0,
}
