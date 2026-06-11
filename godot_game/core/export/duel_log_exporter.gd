class_name DuelLogExporter
extends RefCounted

const SUMMARY_COLUMNS: Array[String] = [
	"seed",
	"winner_id",
	"attacker_id",
	"defender_id",
	"attacker_health_final",
	"defender_health_final",
	"rounds_played",
]

const ROUND_COLUMNS: Array[String] = [
	"seed",
	"round",
	"att_move",
	"def_move",
	"att_damage",
	"def_damage",
]


static func build_summary_row(game_seed: int, result: Dictionary, attacker_id: String, defender_id: String) -> Dictionary:
	var log: Array = result.get("log", [])
	return {
		"seed": str(game_seed),
		"winner_id": str(result.get("winner_id", "")),
		"attacker_id": attacker_id,
		"defender_id": defender_id,
		"attacker_health_final": str(result.get("attacker_health", 0)),
		"defender_health_final": str(result.get("defender_health", 0)),
		"rounds_played": str(log.size()),
	}


static func build_round_rows(game_seed: int, result: Dictionary) -> Array:
	var rows: Array = []
	for entry in result.get("log", []):
		rows.append({
			"seed": str(game_seed),
			"round": str(entry.get("round", 0)),
			"att_move": str(entry.get("att_move", "")),
			"def_move": str(entry.get("def_move", "")),
			"att_damage": str(entry.get("att_damage", 0)),
			"def_damage": str(entry.get("def_damage", 0)),
		})
	return rows


static func render_csv(summary_row: Dictionary, round_rows: Array) -> String:
	var lines: PackedStringArray = []
	lines.append(",".join(SUMMARY_COLUMNS))
	lines.append(_row_to_csv(summary_row, SUMMARY_COLUMNS))
	if not round_rows.is_empty():
		lines.append("")
		lines.append(",".join(ROUND_COLUMNS))
		for row in round_rows:
			lines.append(_row_to_csv(row, ROUND_COLUMNS))
	return "\n".join(lines) + "\n"


static func write_result(
	game_seed: int,
	result: Dictionary,
	attacker_id: String,
	defender_id: String,
	output_path: String
) -> String:
	var summary := build_summary_row(game_seed, result, attacker_id, defender_id)
	var rounds := build_round_rows(game_seed, result)
	var csv := render_csv(summary, rounds)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open duel CSV path: %s" % output_path)
		return ""
	file.store_string(csv)
	file.close()
	return ProjectSettings.globalize_path(output_path)


static func default_output_path(game_seed: int) -> String:
	return "user://duel_seed_%d.csv" % game_seed


static func _row_to_csv(row: Dictionary, columns: Array[String]) -> String:
	var values: PackedStringArray = []
	for column in columns:
		values.append(_escape_csv_field(str(row.get(column, ""))))
	return ",".join(values)


static func _escape_csv_field(value: String) -> String:
	if value.find(",") == -1 and value.find("\"") == -1 and value.find("\n") == -1:
		return value
	return "\"%s\"" % value.replace("\"", "\"\"")
