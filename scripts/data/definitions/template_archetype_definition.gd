# TemplateArchetypeDefinition
# -----------------------------------------------------------------------------
# Architecture role: Data Definition (validation rule profile).
# Responsibilities:
# - Defines high-level archetype constraints used by template validation.
extends Resource
class_name TemplateArchetypeDefinition

@export var id: StringName
@export var display_name: String
@export var required_object_categories: Array[StringName] = []
@export var minimum_block_count: int = 1
