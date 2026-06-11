class_name TestAssert
extends RefCounted

var failures: Array[String] = []
var assertions_run: int = 0
var current_module: String = ""


func begin_module(module_name: String) -> void:
	current_module = module_name


func check(condition: bool, message: String) -> void:
	assertions_run += 1
	if not condition:
		failures.append(_format_failure(message))


func eq(actual, expected, message: String) -> void:
	assertions_run += 1
	if actual != expected:
		failures.append(_format_failure("%s (expected %s, got %s)" % [message, str(expected), str(actual)]))


func has_failures() -> bool:
	return not failures.is_empty()


func _format_failure(message: String) -> String:
	if current_module.is_empty():
		return message
	return "[%s] %s" % [current_module, message]
