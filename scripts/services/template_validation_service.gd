extends RefCounted
class_name TemplateValidationService

func validate_template(template: BuildingTemplateDefinition, archetype: TemplateArchetypeDefinition) -> Dictionary:
	var errors: Array[String] = []
	var present_categories := _extract_object_categories(template)

	for category in archetype.required_object_categories:
		if not present_categories.has(category):
			errors.append("Missing required functional object category: %s" % [String(category)])

	return {
		"is_valid": errors.is_empty(),
		"errors": errors,
	}

func _extract_object_categories(template: BuildingTemplateDefinition) -> Dictionary:
	var categories := {}
	for object_id in template.object_placements.keys():
		# V1: object id prefix acts as category key (ex: bed_basic -> bed).
		var split := String(object_id).split("_")
		var category := StringName(split[0]) if split.size() > 0 else StringName(object_id)
		categories[category] = true
	return categories
