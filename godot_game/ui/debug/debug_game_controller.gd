class_name DebugGameController
extends RefCounted

var _result: Dictionary = {}
var _step: int = 0
var _game_seed: int = 42
var _rounds: int = 3


func get_result() -> Dictionary:
	return _result


func load_from_result(result: Dictionary, game_seed: int = 42, rounds: int = 3) -> void:
	_result = result
	_step = 0
	_game_seed = game_seed
	_rounds = rounds


func load_simulation(game_seed: int, rounds: int) -> void:
	load_from_result(GameSimulator.run(game_seed, rounds), game_seed, rounds)


func export_csv() -> String:
	return DebugRunExporter.write_to_user_path(_result, _game_seed, _rounds)


func export_csv_content() -> String:
	return DebugRunExporter.render_csv(DebugRunExporter.build_rows(_result))


func step_forward() -> void:
	if _step < _total_steps():
		_step += 1


func step_backward() -> void:
	if _step > 0:
		_step -= 1


func set_step(step: int) -> void:
	_step = clampi(step, 0, _total_steps())


func can_step() -> bool:
	return _step < _total_steps()


func current_view() -> Dictionary:
	var baseline: Dictionary = _result.get("replay_baseline", {})
	var log: EventLog = _result.get("event_log")
	if baseline.is_empty() or log == null:
		return _empty_view()

	var replayed := EventLogReplay.build_view_at_step(baseline, log, _step)
	return {
		"step": replayed["step"],
		"total_steps": replayed["total_steps"],
		"round_number": replayed["round_number"],
		"active_player_index": replayed["active_player_index"],
		"players": replayed["players"],
		"board": replayed["cities"],
		"events_text": replayed["events_text"],
		"last_event_detail": replayed.get("last_event_detail", ""),
	}


func _total_steps() -> int:
	var log: EventLog = _result.get("event_log")
	if log == null:
		return 0
	return log.entries.size()


func _empty_view() -> Dictionary:
	return {
		"step": 0,
		"total_steps": 0,
		"round_number": 0,
		"active_player_index": 0,
		"players": [],
		"board": [],
		"events_text": "",
		"last_event_detail": "",
	}
