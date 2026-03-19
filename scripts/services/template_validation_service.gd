# TemplateValidationService
# -----------------------------------------------------------------------------
# Architecture role: Service (template authoring validation rules).
# Responsibilities:
# - Validates saved/built templates against selected archetype requirements.
# - Resolves functional object categories from explicit entries or definitions.
# - Supports legacy and V1 object formats during transition.
extends RefCounted
class_name TemplateValidationService

const FUNCTIONAL_OBJECT_DEFINITIONS: Array[FunctionalObjectDefinition] = [
	preload("res://data/definitions/objects/bed_basic.tres"),
	preload("res://data/definitions/objects/desk_basic.tres"),
	preload("res://data/definitions/objects/board_basic.tres"),
	preload("res://data/definitions/objects/admin_desk_basic.tres"),
	preload("res://data/definitions/objects/storage_basic.tres"),
	preload("res://data/definitions/objects/stall_basic.tres"),
	preload("res://data/definitions/objects/field_basic.tres"),
]

var _category_by_object_id: Dictionary = {}

# Prebuilds object_id -> category lookup for stable validation behavior.
func _init() -> void:
	for object_def in FUNCTIONAL_OBJECT_DEFINITIONS:
		_category_by_object_id[object_def.id] = object_def.category

# Validates template completeness against archetype business requirements.
# Side effects: none.
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

# Extracts all functional categories present in legacy and V1 object formats.
func _extract_object_categories(template: BuildingTemplateDefinition) -> Dictionary:
	var categories := {}
	for object_id in template.object_placements.keys():
		_register_category_from_object_entry(categories, {"object_id": object_id})

	for entry in template.object_instances:
		_register_category_from_object_entry(categories, entry)

	return categories

# Registers one object entry into category set with fallback inference rules.
func _register_category_from_object_entry(categories: Dictionary, entry: Dictionary) -> void:
	var explicit_category: StringName = entry.get("category", &"")
	if explicit_category != &"":
		categories[explicit_category] = true
		return

	var object_id: StringName = entry.get("object_id", &"")
	if object_id == &"":
		return
	if _category_by_object_id.has(object_id):
		categories[_category_by_object_id[object_id]] = true
		return

	# Fallback for unknown objects: use id prefix (ex: bed_basic -> bed).
	var split := String(object_id).split("_")
	var inferred_category := StringName(split[0]) if split.size() > 0 else StringName(object_id)
	categories[inferred_category] = true
