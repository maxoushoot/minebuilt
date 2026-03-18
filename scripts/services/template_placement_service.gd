extends RefCounted
class_name TemplatePlacementService

const DEFAULT_BLOCK_ID := &"grass"

func evaluate_placement(
	template: BuildingTemplateDefinition,
	state: VoxelBuildState,
	origin: Vector3i,
	rotation: int,
	bounds: Vector3i
) -> Dictionary:
	if template == null:
		return {"is_valid": false, "errors": ["No template selected."]}
	if state == null:
		return {"is_valid": false, "errors": ["World state unavailable."]}

	var errors: Array[String] = []
	var transformed_blocks := transformed_block_instances(template, origin, rotation)
	if transformed_blocks.is_empty():
		errors.append("Template has no block to place.")

	for instance in transformed_blocks:
		var cell: Vector3i = instance.get("cell", Vector3i.ZERO)
		if not _is_inside_bounds(cell, bounds):
			errors.append("Out of bounds at %s." % [str(cell)])
			continue
		if state.cells.has(cell):
			errors.append("Collision at %s." % [str(cell)])

	return {
		"is_valid": errors.is_empty(),
		"errors": errors,
		"block_instances": transformed_blocks,
		"object_instances": transformed_object_instances(template, origin, rotation),
	}

func transformed_block_instances(
	template: BuildingTemplateDefinition,
	origin: Vector3i,
	rotation: int
) -> Array[Dictionary]:
	var source_blocks: Array[Dictionary] = []
	if not template.block_instances.is_empty():
		source_blocks = template.block_instances
	else:
		for cell in template.block_cells:
			source_blocks.append({
				"cell": cell,
				"block_id": DEFAULT_BLOCK_ID,
				"rotation": 0,
			})

	var transformed: Array[Dictionary] = []
	var normalized_rotation := posmod(rotation, 4)
	for entry in source_blocks:
		var local_cell: Vector3i = entry.get("cell", Vector3i.ZERO)
		var world_cell := origin + rotate_cell_90(local_cell, normalized_rotation)
		transformed.append({
			"cell": world_cell,
			"block_id": entry.get("block_id", DEFAULT_BLOCK_ID),
			"rotation": posmod(int(entry.get("rotation", 0)) + normalized_rotation, 4),
		})
	return transformed

func transformed_object_instances(
	template: BuildingTemplateDefinition,
	origin: Vector3i,
	rotation: int
) -> Array[Dictionary]:
	var transformed: Array[Dictionary] = []
	var normalized_rotation := posmod(rotation, 4)

	for entry in template.object_instances:
		var local_cell: Vector3i = entry.get("cell", Vector3i.ZERO)
		var world_cell := origin + rotate_cell_90(local_cell, normalized_rotation)
		transformed.append({
			"object_id": entry.get("object_id", &""),
			"cell": world_cell,
			"rotation": posmod(int(entry.get("rotation", 0)) + normalized_rotation, 4),
		})
	return transformed

func create_building_instance(
	template: BuildingTemplateDefinition,
	origin: Vector3i,
	rotation: int,
	block_instances: Array[Dictionary],
	object_instances: Array[Dictionary]
) -> BuildingInstance:
	var instance := BuildingInstance.new()
	instance.id = StringName("building_%s_%d" % [String(template.id), Time.get_unix_time_from_system()])
	instance.template_id = template.id
	instance.template_name = template.display_name
	instance.archetype_id = template.archetype_id
	instance.origin_cell = origin
	instance.rotation = posmod(rotation, 4)
	instance.block_instances = block_instances.duplicate(true)
	instance.object_instances = object_instances.duplicate(true)
	return instance

func rotate_cell_90(cell: Vector3i, rotation: int) -> Vector3i:
	match posmod(rotation, 4):
		0:
			return cell
		1:
			return Vector3i(-cell.z, cell.y, cell.x)
		2:
			return Vector3i(-cell.x, cell.y, -cell.z)
		3:
			return Vector3i(cell.z, cell.y, -cell.x)
		_:
			return cell

func _is_inside_bounds(cell: Vector3i, bounds: Vector3i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.z < 0:
		return false
	return cell.x < bounds.x and cell.y < bounds.y and cell.z < bounds.z
