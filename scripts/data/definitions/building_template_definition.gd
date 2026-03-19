# BuildingTemplateDefinition
# -----------------------------------------------------------------------------
# Architecture role: Data Definition (template authoring artifact).
# Responsibilities:
# - Describes reusable building shape and functional object placements.
# - Supports legacy object_placements and V1 object_instances formats.
extends Resource
class_name BuildingTemplateDefinition

@export var id: StringName
@export var display_name: String
@export var archetype_id: StringName
@export var block_cells: Array[Vector3i] = []
@export var block_instances: Array[Dictionary] = []
# Legacy format: Dictionary[object_id, Vector3i]
@export var object_placements: Dictionary = {}
# V1 format: Array[{"object_id": StringName, "cell": Vector3i, "rotation": int}]
@export var object_instances: Array[Dictionary] = []
