extends RefCounted
class_name GridPathfindingService

var _astar := AStarGrid3D.new()

func configure(bounds: Rect3i) -> void:
	_astar.region = bounds
	_astar.cell_size = Vector3.ONE
	_astar.diagonal_mode = AStarGrid3D.DIAGONAL_MODE_NEVER
	_astar.update()

func set_point_walkable(cell: Vector3i, walkable: bool) -> void:
	_astar.set_point_solid(cell, not walkable)

func get_id_path(from_cell: Vector3i, to_cell: Vector3i) -> Array[Vector3i]:
	if not _astar.is_in_boundsv(from_cell) or not _astar.is_in_boundsv(to_cell):
		return []
	return _astar.get_id_path(from_cell, to_cell)
