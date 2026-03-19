# GridMapBlockRenderer
# -----------------------------------------------------------------------------
# Architecture role: Rendering system (visual projection of voxel state).
# Responsibilities:
# - Maps block ids to MeshLibrary items and colors.
# - Renders full/partial voxel cells to GridMap.
# - Displays edit/placement ghost visualization.
# Side effects:
# - Mutates scene graph render nodes only (no gameplay state mutation).
extends Node3D
class_name GridMapBlockRenderer

@onready var _grid_map: GridMap = %GridMap
@onready var _ghost_mesh: MeshInstance3D = %GhostMesh

var _block_to_item: Dictionary = {}
var _block_colors: Dictionary = {}

# Configures runtime mesh library from block catalog definitions.
func configure(block_entries: Array[Dictionary]) -> void:
	var mesh_library := MeshLibrary.new()
	_block_to_item.clear()
	_block_colors.clear()

	for i in block_entries.size():
		var entry: Dictionary = block_entries[i]
		var block_id: StringName = entry.get("id", &"unknown")
		var color: Color = entry.get("color", Color.WHITE)
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE

		var material := StandardMaterial3D.new()
		material.albedo_color = color
		mesh.material = material

		mesh_library.create_item(i)
		mesh_library.set_item_name(i, String(block_id))
		mesh_library.set_item_mesh(i, mesh)
		_block_to_item[block_id] = i
		_block_colors[block_id] = color

	_grid_map.mesh_library = mesh_library

# Re-renders entire voxel state.
func render_full(state: VoxelBuildState) -> void:
	_grid_map.clear()
	if state == null:
		return
	for cell_key in state.cells.keys():
		var cell: Vector3i = cell_key
		render_cell(cell, state.cells[cell])

# Renders or clears one cell depending on block payload.
func render_cell(cell: Vector3i, cell_data: Dictionary) -> void:
	if not cell_data.has("block_id"):
		_grid_map.set_cell_item(cell, -1)
		return

	var block_id: StringName = cell_data.get("block_id", &"unknown")
	if not _block_to_item.has(block_id):
		_grid_map.set_cell_item(cell, -1)
		return

	var rotation: int = int(cell_data.get("rotation", 0)) % 4
	_grid_map.set_cell_item(cell, _block_to_item[block_id], rotation)

func clear_cell(cell: Vector3i) -> void:
	_grid_map.set_cell_item(cell, -1)

func world_to_cell(world_point: Vector3) -> Vector3i:
	return _grid_map.local_to_map(_grid_map.to_local(world_point))

# Shows translucent ghost block for current cursor operation.
func set_ghost(cell: Vector3i, block_id: StringName, rotation: int = 0) -> void:
	var color: Color = _block_colors.get(block_id, Color.WHITE)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.35)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = true

	if _ghost_mesh.mesh == null:
		var ghost_box := BoxMesh.new()
		ghost_box.size = Vector3.ONE * 1.01
		_ghost_mesh.mesh = ghost_box

	_ghost_mesh.material_override = material
	_ghost_mesh.global_position = _grid_map.to_global(_grid_map.map_to_local(cell))
	_ghost_mesh.rotation_degrees.y = float((rotation % 4) * 90)
	_ghost_mesh.visible = true

func hide_ghost() -> void:
	_ghost_mesh.visible = false
