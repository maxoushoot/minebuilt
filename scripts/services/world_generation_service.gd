# WorldGenerationService
# -----------------------------------------------------------------------------
# Architecture role: Service (procedural bootstrap data generation).
# Responsibilities:
# - Generates initial terrain voxel dictionary for world runtime bootstrap.
# - Applies a simple deterministic river pass from session seed.
extends RefCounted
class_name WorldGenerationService

# Produces initial world voxel cells dictionary.
# Side effects: none (pure generation).
func generate_height_map(width: int, depth: int, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var map := {}
	for x in width:
		for z in depth:
			var base_height := 2
			var noise_height := rng.randi_range(-1, 2)
			map[Vector3i(x, base_height + noise_height, z)] = {"block_id": &"grass", "rotation": 0}
			for y in range(base_height + noise_height):
				map[Vector3i(x, y, z)] = {"block_id": &"dirt", "rotation": 0}

	_apply_simple_river(map, width, depth, rng)
	return map

# Applies a thin river corridor on top of generated base terrain.
func _apply_simple_river(map: Dictionary, width: int, depth: int, rng: RandomNumberGenerator) -> void:
	var river_x := rng.randi_range(width / 4, width * 3 / 4)
	for z in depth:
		for offset in range(-1, 2):
			var cell := Vector3i(river_x + offset, 1, z)
			map[cell] = {"block_id": &"water", "rotation": 0}
