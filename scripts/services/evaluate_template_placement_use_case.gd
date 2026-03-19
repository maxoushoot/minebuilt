extends RefCounted
class_name EvaluateTemplatePlacementUseCase

var _template_placement: TemplatePlacementService

func setup(template_placement: TemplatePlacementService) -> EvaluateTemplatePlacementUseCase:
	_template_placement = template_placement
	return self

func execute(
	session: GameSessionState,
	template: BuildingTemplateDefinition,
	origin: Vector3i,
	rotation: int,
	world_bounds: Vector3i
) -> Dictionary:
	if _template_placement == null:
		return UseCaseResultFactory.failure(&"service_unavailable", "Services de placement indisponibles.")
	if session == null or session.world_voxel_state == null:
		return UseCaseResultFactory.failure(&"runtime_missing", "Runtime monde indisponible.")
	if template == null:
		return UseCaseResultFactory.failure(&"template_missing", "Sélectionnez un template avant de poser.")

	var evaluation := _template_placement.evaluate_placement(
		template,
		session.world_voxel_state,
		origin,
		rotation,
		world_bounds
	)
	var payload := {
		"errors": evaluation.get("errors", []),
		"block_instances": evaluation.get("block_instances", []),
		"object_instances": evaluation.get("object_instances", []),
	}
	if evaluation.get("is_valid", false):
		return UseCaseResultFactory.success(&"placement_valid", "Zone valide. Placement possible.", payload)
	return UseCaseResultFactory.failure(&"placement_invalid", "Placement refusé: collisions ou hors limites.", payload)
