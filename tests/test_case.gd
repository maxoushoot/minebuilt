extends RefCounted
class_name TestCase

var _failures: Array[String] = []
var _passes: int = 0

func run() -> void:
	push_error("TestCase.run() doit être implémenté par les classes de test.")

func assert_true(value: Variant, message: String) -> void:
	if bool(value):
		_passes += 1
		return
	_failures.append(message)

func assert_false(value: Variant, message: String) -> void:
	assert_true(not bool(value), message)

func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		_passes += 1
		return
	_failures.append("%s | attendu=%s obtenu=%s" % [message, str(expected), str(actual)])

func assert_has(container: Variant, key: Variant, message: String) -> void:
	if typeof(container) == TYPE_DICTIONARY and container.has(key):
		_passes += 1
		return
	if typeof(container) == TYPE_ARRAY and container.has(key):
		_passes += 1
		return
	_failures.append(message)

func assert_not_empty(value: Variant, message: String) -> void:
	if value is Array or value is Dictionary or value is PackedByteArray or value is PackedInt32Array or value is PackedStringArray or value is String:
		if value.size() > 0:
			_passes += 1
			return
	_failures.append(message)

func summarize() -> Dictionary:
	return {
		"passes": _passes,
		"failures": _failures.duplicate(),
		"failed": _failures.size() > 0,
	}
