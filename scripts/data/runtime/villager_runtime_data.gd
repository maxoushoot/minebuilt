extends Resource
class_name VillagerRuntimeData

const STATE_IDLE := &"idle"
const STATE_GOING_TO_WORK := &"going_to_work"
const STATE_WORKING := &"working"
const STATE_TRANSPORTING := &"transporting"
const STATE_RETURNING_HOME := &"returning_home"

@export var id: int = -1
@export var display_name: String = ""
@export var home_building_id: StringName = &""
@export var assigned_building_id: StringName = &""
@export var state: StringName = STATE_IDLE
@export var current_cell: Vector3i = Vector3i.ZERO
@export var path_cells: Array[Vector3i] = []
@export var carry_resource: StringName = &""
@export var carry_units: int = 0
@export var logistics_job: Dictionary = {}
