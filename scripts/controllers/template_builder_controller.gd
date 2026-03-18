extends Node3D
class_name TemplateBuilderController

const BUILD_AREA_SIZE := Vector2i(100, 100)

var _validation := TemplateValidationService.new()

@onready var _status_label: Label = %StatusLabel

func _ready() -> void:
	_status_label.text = "Template zone ready (%dx%d)" % [BUILD_AREA_SIZE.x, BUILD_AREA_SIZE.y]

func validate_sample(template: BuildingTemplateDefinition, archetype: TemplateArchetypeDefinition) -> Dictionary:
	return _validation.validate_template(template, archetype)
