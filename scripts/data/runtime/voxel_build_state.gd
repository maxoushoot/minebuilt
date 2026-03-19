# VoxelBuildState
# -----------------------------------------------------------------------------
# Architecture role: Runtime Data (canonical voxel map container).
# Responsibilities:
# - Holds sparse voxel cells keyed by Vector3i.
# - Shared by world runtime and template-builder runtime contexts.
# Notes:
# - Cell payload format is intentionally dictionary-based for compatibility with
#   renderer/pathfinding/template placement services.
extends Resource
class_name VoxelBuildState

# Dictionary[Vector3i, Dictionary] where value = {"block_id": StringName, "rotation": int}
@export var cells: Dictionary = {}
