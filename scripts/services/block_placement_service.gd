# BlockPlacementService
# -----------------------------------------------------------------------------
# Architecture role: Service (low-level voxel mutation helper).
# Responsibilities:
# - Adds/removes/queries block payloads from a VoxelBuildState.
# - Provides a shared, minimal mutation API used by controllers/use cases.
extends RefCounted
class_name BlockPlacementService

# Writes or replaces one voxel cell entry.
func place_block(state: VoxelBuildState, cell: Vector3i, block_id: StringName, rotation: int = 0) -> bool:
	if state == null:
		return false
	state.cells[cell] = {
		"block_id": block_id,
		"rotation": rotation % 4,
	}
	return true

# Removes one voxel cell entry if present.
func remove_block(state: VoxelBuildState, cell: Vector3i) -> bool:
	if state == null:
		return false
	if not state.cells.has(cell):
		return false
	state.cells.erase(cell)
	return true

# Reads one voxel cell payload.
func get_block(state: VoxelBuildState, cell: Vector3i) -> Dictionary:
	if state == null:
		return {}
	return state.cells.get(cell, {})

# Checks voxel occupancy for a given cell.
func has_block(state: VoxelBuildState, cell: Vector3i) -> bool:
	if state == null:
		return false
	return state.cells.has(cell)
