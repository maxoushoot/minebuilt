extends RefCounted
class_name UseCaseResultFactory

static func success(code: StringName, message: String, payload: Dictionary = {}) -> Dictionary:
	return {
		"success": true,
		"code": code,
		"message": message,
		"payload": payload,
	}

static func failure(code: StringName, message: String, payload: Dictionary = {}) -> Dictionary:
	return {
		"success": false,
		"code": code,
		"message": message,
		"payload": payload,
	}
