class_name UnderworldPressureRunner
extends RefCounted

const CSV_COLUMNS: Array[String] = [
	"seed",
	"turns_played",
	"rounds_played",
	"breach_count",
	"peak_demon_count",
	"spread_event_count",
	"game_over",
	"winner_id",
	"outcome_reason",
	"policy_name",
]


static func run_games(
	game_count: int,
	start_seed: int,
	max_turns: int,
	policy: String = BotTurnResolver.POLICY_HEURISTIC
) -> Array:
	var rows: Array = []
	for offset in range(game_count):
		var game_seed := start_seed + offset
		rows.append(_run_single_game(game_seed, max_turns, policy))
	return rows


static func render_csv(rows: Array) -> String:
	var lines: PackedStringArray = []
	lines.append(",".join(CSV_COLUMNS))
	for row in rows:
		var values: PackedStringArray = []
		for column in CSV_COLUMNS:
			values.append(_escape_csv_field(str(row.get(column, ""))))
		lines.append(",".join(values))
	return "\n".join(lines) + "\n"


static func write_csv(rows: Array, output_path: String) -> String:
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open underworld pressure CSV path: %s" % output_path)
		return ""
	file.store_string(render_csv(rows))
	file.close()
	return ProjectSettings.globalize_path(output_path)


static func _run_single_game(game_seed: int, max_turns: int, policy: String) -> Dictionary:
	var session := BotGameSession.start_four_player_underworld_pressure(game_seed, policy)
	var peak_demons := _total_demons(session.state)
	var spread_event_count := 0

	while not session.finished and session.player_turn_count < max_turns:
		var events_before := session.events.size()
		session.advance_one_player_turn()
		for index in range(events_before, session.events.size()):
			var event = session.events[index]
			if event is DemonSpreadEvent:
				spread_event_count += 1
		peak_demons = maxi(peak_demons, _total_demons(session.state))

	return _row_from_summary({
		"seed": game_seed,
		"policy_name": policy,
		"finished": session.finished,
		"winner_id": session.state.winner_id,
		"player_turn_count": session.player_turn_count,
		"round_number": session.state.round_number,
		"breach_count": session.state.breach_count,
		"peak_demon_count": peak_demons,
		"spread_event_count": spread_event_count,
		"initial_demon_count": _total_demons_at_start(game_seed),
	})


static func _row_from_summary(summary: Dictionary) -> Dictionary:
	var finished: bool = summary.get("finished", false)
	var winner_id: int = summary.get("winner_id", -1)
	var outcome_reason := "turn_limit"
	if finished and winner_id >= 0:
		outcome_reason = "victory_points"
	elif finished and winner_id < 0:
		outcome_reason = "breach"

	return {
		"seed": str(summary.get("seed", "")),
		"turns_played": str(summary.get("player_turn_count", 0)),
		"rounds_played": str(summary.get("round_number", 0)),
		"breach_count": str(summary.get("breach_count", 0)),
		"peak_demon_count": str(summary.get("peak_demon_count", 0)),
		"spread_event_count": str(summary.get("spread_event_count", 0)),
		"game_over": str(finished).to_lower(),
		"winner_id": str(winner_id),
		"outcome_reason": outcome_reason,
		"policy_name": str(summary.get("policy_name", "")),
	}


static func _total_demons(state: GameState) -> int:
	var total := 0
	for key in state.demon_counts_by_node.keys():
		total += int(state.demon_counts_by_node[key])
	return total


static func _total_demons_at_start(game_seed: int) -> int:
	var state := ScenarioBuilder.build_underworld_pressure_game(game_seed)
	return _total_demons(state)


static func _escape_csv_field(value: String) -> String:
	if value.find(",") == -1 and value.find("\"") == -1 and value.find("\n") == -1:
		return value
	return "\"%s\"" % value.replace("\"", "\"\"")
