# MainMenuController
# -----------------------------------------------------------------------------
# Architecture role: Controller (menu UI orchestration).
# Responsibilities:
# - Handles main menu button actions.
# - Resets session when entering runtime modes to ensure clean state.
extends Control
class_name MainMenuController

# Starts world mode from a fresh session.
func _on_start_world_pressed() -> void:
	AppServices.reset_session()
	AppState.set_mode(AppState.MODE_WORLD)

# Starts template builder mode from a fresh session.
func _on_template_builder_pressed() -> void:
	AppServices.reset_session()
	AppState.set_mode(AppState.MODE_TEMPLATE_BUILDER)

func _on_quit_pressed() -> void:
	get_tree().quit()
