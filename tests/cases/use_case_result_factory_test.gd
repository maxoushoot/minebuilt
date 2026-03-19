extends "res://tests/test_case.gd"

func run() -> void:
	var success := UseCaseResultFactory.success(&"ok", "Done", {"value": 12})
	assert_true(success.get("success", false), "UseCaseResultFactory.success doit marquer success=true")
	assert_eq(success.get("code", &""), &"ok", "UseCaseResultFactory.success doit conserver le code")
	assert_eq(success.get("payload", {}).get("value", -1), 12, "UseCaseResultFactory.success doit conserver le payload")

	var failure := UseCaseResultFactory.failure(&"invalid", "Nope", {"reason": "bounds"})
	assert_false(failure.get("success", true), "UseCaseResultFactory.failure doit marquer success=false")
	assert_eq(failure.get("code", &""), &"invalid", "UseCaseResultFactory.failure doit conserver le code")
	assert_eq(failure.get("payload", {}).get("reason", ""), "bounds", "UseCaseResultFactory.failure doit conserver le payload")
