extends RefCounted
class_name BlockPlacementService

func place_block(state: VoxelBuildState, cell: Vector3i, block_id: StringName, rotation: int = 0) -> bool:
	if state == null:
		return false
	state.cells[cell] = {
		"block_id": block_id,
		"rotation": rotation % 4,
	}
	return true

func remove_block(state: VoxelBuildState, cell: Vector3i) -> bool:
	if state == null:
		return false
	if not state.cells.has(cell):
		return false
	state.cells.erase(cell)
	return true

func get_block(state: VoxelBuildState, cell: Vector3i) -> Dictionary:
	if state == null:
		return {}
	return state.cells.get(cell, {})

func has_block(state: VoxelBuildState, cell: Vector3i) -> bool:
	if state == null:
		return false
	return state.cells.has(cell)
