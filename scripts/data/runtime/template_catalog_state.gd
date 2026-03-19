# TemplateCatalogState
# -----------------------------------------------------------------------------
# Architecture role: Runtime Data (template library for session).
# Responsibilities:
# - Stores templates available for placement in world mode.
# - Acts as the mutable in-session catalog populated from defaults and builder.
extends Resource
class_name TemplateCatalogState

@export var templates: Array[BuildingTemplateDefinition] = []
