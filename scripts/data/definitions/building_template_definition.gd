extends Resource
class_name BuildingTemplateDefinition

@export var id: StringName
@export var display_name: String
@export var archetype_id: StringName
@export var block_cells: Array[Vector3i] = []
@export var object_placements: Dictionary = {}
