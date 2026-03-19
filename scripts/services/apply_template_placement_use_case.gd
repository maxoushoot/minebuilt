extends RefCounted
class_name ApplyTemplatePlacementUseCase

var _population: PopulationService
var _template_placement: TemplatePlacementService
var _block_placement: BlockPlacementService
var _pathfinding: GridPathfindingService
var _logistics: LogisticsService
var _session_runtime: SessionRuntimeService

func setup(
	population: PopulationService,
	template_placement: TemplatePlacementService,
	block_placement: BlockPlacementService,
	pathfinding: GridPathfindingService,
	logistics: LogisticsService,
	session_runtime: SessionRuntimeService
) -> ApplyTemplatePlacementUseCase:
	_population = population
	_template_placement = template_placement
	_block_placement = block_placement
	_pathfinding = pathfinding
	_logistics = logistics
	_session_runtime = session_runtime
	return self

func execute(
	session: GameSessionState,
	template: BuildingTemplateDefinition,
	origin: Vector3i,
	rotation: int,
	world_bounds: Vector3i
) -> Dictionary:
	if not _has_dependencies():
		return UseCaseResultFactory.failure(&"service_unavailable", "Services de placement indisponibles.")
	if session == null or session.village == null or session.world_voxel_state == null:
		return UseCaseResultFactory.failure(&"runtime_missing", "Runtime monde indisponible.")
	if template == null:
		return UseCaseResultFactory.failure(&"template_missing", "Sélectionnez un template avant de poser.")

	var village := session.village
	var world_state := session.world_voxel_state
	var evaluation := _template_placement.evaluate_placement(template, world_state, origin, rotation, world_bounds)
	if not evaluation.get("is_valid", false):
		return UseCaseResultFactory.failure(&"placement_invalid", "Placement refusé: collisions ou hors limites.", {
			"errors": evaluation.get("errors", []),
		})

	var transformed_blocks: Array[Dictionary] = evaluation.get("block_instances", [])
	var transformed_objects: Array[Dictionary] = evaluation.get("object_instances", [])
	for entry in transformed_blocks:
		var cell: Vector3i = entry.get("cell", Vector3i.ZERO)
		var block_id: StringName = entry.get("block_id", &"grass")
		var rot: int = int(entry.get("rotation", 0))
		_block_placement.place_block(world_state, cell, block_id, rot)

	var instance := _template_placement.create_building_instance(
		template,
		origin,
		rotation,
		transformed_blocks,
		transformed_objects
	)
	instance.worker_capacity = _population.worker_capacity_for_building(instance)
	village.placed_buildings.append(instance)

	var spawned_villagers := _population.spawn_villagers_for_house(instance, village.villagers)
	for villager in spawned_villagers:
		village.villagers.append(villager)

	var changed_cells := _extract_changed_cells(transformed_blocks)
	_pathfinding.apply_local_map_update(changed_cells, world_state, village.placed_buildings)
	_logistics.initialize_village_logistics(village, _pathfinding)
	_session_runtime.sync_transient_world_blocks(session)

	return UseCaseResultFactory.success(&"placed", "Template '%s' posé avec succès." % [template.display_name], {
		"building_instance_id": instance.id,
		"spawned_villager_count": spawned_villagers.size(),
		"changed_cells": changed_cells,
	})

func _has_dependencies() -> bool:
	return (
		_population != null
		and _template_placement != null
		and _block_placement != null
		and _pathfinding != null
		and _logistics != null
		and _session_runtime != null
	)

func _extract_changed_cells(transformed_blocks: Array[Dictionary]) -> Array[Vector3i]:
	var changed: Array[Vector3i] = []
	for entry in transformed_blocks:
		changed.append(entry.get("cell", Vector3i.ZERO))
	return changed
