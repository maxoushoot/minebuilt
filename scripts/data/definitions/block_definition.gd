# BlockDefinition
# -----------------------------------------------------------------------------
# Architecture role: Data Definition (block catalog entry).
# Responsibilities:
# - Declares metadata for a placeable voxel block.
extends Resource
class_name BlockDefinition

@export var id: StringName
@export var display_name: String
@export var texture_id: StringName
@export var walkable: bool = true
