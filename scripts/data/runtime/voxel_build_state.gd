extends Resource
class_name VoxelBuildState

# Dictionary[Vector3i, Dictionary] where value = {"block_id": StringName, "rotation": int}
@export var cells: Dictionary = {}
