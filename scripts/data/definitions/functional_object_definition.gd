# FunctionalObjectDefinition
# -----------------------------------------------------------------------------
# Architecture role: Data Definition (functional object catalog entry).
# Responsibilities:
# - Declares object id/category and footprint used in template workflows.
extends Resource
class_name FunctionalObjectDefinition

@export var id: StringName
@export var display_name: String
@export var category: StringName
@export var footprint_cells: Vector3i = Vector3i.ONE
