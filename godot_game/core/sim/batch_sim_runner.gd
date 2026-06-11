class_name BatchSimRunner
extends RefCounted

const CSV_COLUMNS: Array[String] = [
	"seed",
	"turns_played",
	"game_over",
	"winner_id",
	"outcome_reason",
	"vp_p0",
	"vp_p1",
	"vp_p2",
	"vp_p3",
	"city_count",
	"road_count",
	"breach_count",
	"demon_count",
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
		push_error("Failed to open batch CSV path: %s" % output_path)
		return ""
	file.store_string(render_csv(rows))
	file.close()
	return ProjectSettings.globalize_path(output_path)


static func _run_single_game(game_seed: int, max_turns: int, policy: String) -> Dictionary:
	var session := BotGameSession.start_four_player(game_seed, policy)
	session.run_until_finished(max_turns)
	var summary := _summary_from_session(session)
	return _row_from_summary(summary)


static func _summary_from_session(session: BotGameSession) -> Dictionary:
	var state := session.state
	var vp_by_player := {}
	for player in state.players:
		vp_by_player[player.id] = player.victory_points
	var demon_count := 0
	for key in state.demon_counts_by_node.keys():
		demon_count += int(state.demon_counts_by_node[key])
	return {
		"seed": session.seed,
		"policy_name": session.policy_name,
		"finished": session.finished,
		"winner_id": state.winner_id,
		"player_turn_count": session.player_turn_count,
		"round_number": state.round_number,
		"city_count": state.cities.size(),
		"road_count": state.roads.size(),
		"breach_count": state.breach_count,
		"demon_count": demon_count,
		"vp_by_player": vp_by_player,
		"outcome_reason": _outcome_reason(session),
	}


static func _outcome_reason(session: BotGameSession) -> String:
	if not session.state.game_finished:
		return "turn_limit"
	for i in range(session.events.size() - 1, -1, -1):
		var event = session.events[i]
		if event is GameOverEvent:
			return event.reason
	return ""


static func _row_from_summary(summary: Dictionary) -> Dictionary:
	var vp: Dictionary = summary.get("vp_by_player", {})
	return {
		"seed": str(summary.get("seed", "")),
		"turns_played": str(summary.get("player_turn_count", 0)),
		"game_over": str(summary.get("finished", false)).to_lower(),
		"winner_id": str(summary.get("winner_id", -1)),
		"outcome_reason": str(summary.get("outcome_reason", "")),
		"vp_p0": str(vp.get(0, 0)),
		"vp_p1": str(vp.get(1, 0)),
		"vp_p2": str(vp.get(2, 0)),
		"vp_p3": str(vp.get(3, 0)),
		"city_count": str(summary.get("city_count", 0)),
		"road_count": str(summary.get("road_count", 0)),
		"breach_count": str(summary.get("breach_count", 0)),
		"demon_count": str(summary.get("demon_count", 0)),
		"policy_name": str(summary.get("policy_name", "")),
	}


static func _escape_csv_field(value: String) -> String:
	if value.find(",") == -1 and value.find("\"") == -1 and value.find("\n") == -1:
		return value
	return "\"%s\"" % value.replace("\"", "\"\"")
