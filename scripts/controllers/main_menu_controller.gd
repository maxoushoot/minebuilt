extends Control
class_name MainMenuController

func _on_start_world_pressed() -> void:
	AppServices.reset_session()
	AppState.set_mode(AppState.MODE_WORLD)

func _on_template_builder_pressed() -> void:
	AppServices.reset_session()
	AppState.set_mode(AppState.MODE_TEMPLATE_BUILDER)

func _on_quit_pressed() -> void:
	get_tree().quit()
