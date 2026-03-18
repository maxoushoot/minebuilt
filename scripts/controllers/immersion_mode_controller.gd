extends Node3D
class_name ImmersionModeController

@onready var _hint_label: Label = %HintLabel

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_hint_label.text = "FPS immersion mode (press Esc to return)"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		AppState.set_mode(AppState.MODE_WORLD)
