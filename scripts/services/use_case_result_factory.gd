# UseCaseResultFactory
# -----------------------------------------------------------------------------
# Architecture role: Shared helper for Use Case response normalization.
# Responsibilities:
# - Produces standardized dictionaries consumed by controllers/UI.
# - Ensures each use case result includes success/code/message/payload keys.
extends RefCounted
class_name UseCaseResultFactory

# Builds a standardized successful use-case response.
static func success(code: StringName, message: String, payload: Dictionary = {}) -> Dictionary:
	return {
		"success": true,
		"code": code,
		"message": message,
		"payload": payload,
	}

# Builds a standardized failed use-case response.
static func failure(code: StringName, message: String, payload: Dictionary = {}) -> Dictionary:
	return {
		"success": false,
		"code": code,
		"message": message,
		"payload": payload,
	}
