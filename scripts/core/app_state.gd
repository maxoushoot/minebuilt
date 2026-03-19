# AppState
# -----------------------------------------------------------------------------
# Architecture role: Core System (global app mode state machine).
# Responsibilities:
# - Stores active high-level mode.
# - Emits mode transition events consumed by root controller.
extends Node
class_name AppState

signal mode_changed(previous_mode: StringName, next_mode: StringName)

const MODE_MENU := &"menu"
const MODE_WORLD := &"world"
const MODE_TEMPLATE_BUILDER := &"template_builder"
const MODE_IMMERSION := &"immersion"

var current_mode: StringName = MODE_MENU

# Performs mode transition with idempotence guard and transition signal.
func set_mode(next_mode: StringName) -> void:
	if current_mode == next_mode:
		return
	var previous_mode := current_mode
	current_mode = next_mode
	mode_changed.emit(previous_mode, next_mode)
