extends RefCounted
class_name TemplateValidationService

func validate_template(template: BuildingTemplateDefinition, archetype: TemplateArchetypeDefinition) -> Dictionary:
	var errors: Array[String] = []
	if template.block_cells.size() < max(archetype.minimum_block_count, 1):
		errors.append(
			"Minimum %d block(s) required, current: %d" % [
				max(archetype.minimum_block_count, 1),
				template.block_cells.size(),
			]
		)

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
		_register_category_from_object_id(categories, object_id)

	for entry in template.object_instances:
		var object_id: StringName = entry.get("object_id", &"")
		_register_category_from_object_id(categories, object_id)

	return categories

func _register_category_from_object_id(categories: Dictionary, object_id: StringName) -> void:
	if object_id == &"":
		return
	# V1: object id prefix acts as category key (ex: bed_basic -> bed).
	var split := String(object_id).split("_")
	var category := StringName(split[0]) if split.size() > 0 else StringName(object_id)
	categories[category] = true
