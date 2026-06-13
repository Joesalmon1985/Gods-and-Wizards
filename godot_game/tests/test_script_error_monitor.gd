class_name TestScriptErrorMonitor
extends Logger

var script_errors: Array[String] = []
var engine_errors: Array[String] = []
var _mutex := Mutex.new()


func reset() -> void:
	_mutex.lock()
	script_errors.clear()
	engine_errors.clear()
	_mutex.unlock()


func has_script_errors() -> bool:
	_mutex.lock()
	var result := not script_errors.is_empty()
	_mutex.unlock()
	return result


func has_engine_errors() -> bool:
	_mutex.lock()
	var result := not engine_errors.is_empty()
	_mutex.unlock()
	return result


func script_error_count() -> int:
	_mutex.lock()
	var count := script_errors.size()
	_mutex.unlock()
	return count


func _log_error(
	function: String,
	file: String,
	line: int,
	code: String,
	rationale: String,
	editor_notify: bool,
	error_type: int,
	script_backtraces: Array
) -> void:
	var detail := rationale if not rationale.is_empty() else code
	var entry := "%s at %s:%d in %s" % [detail, file, line, function]
	_mutex.lock()
	match error_type:
		Logger.ERROR_TYPE_SCRIPT:
			script_errors.append(entry)
		Logger.ERROR_TYPE_ERROR, Logger.ERROR_TYPE_SHADER:
			engine_errors.append(entry)
		_:
			pass
	_mutex.unlock()


func _log_message(message: String, error: bool) -> void:
	pass
