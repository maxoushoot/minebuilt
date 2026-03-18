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
