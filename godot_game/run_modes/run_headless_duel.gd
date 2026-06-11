# Headless micro-duel smoke runner — one CombatResolver.resolve_encounter call, CSV export.
# Example:
#   godot --headless --path "<godot_game>" -s res://run_modes/run_headless_duel.gd -- --seed 123 --output user://duel_seed_123.csv

extends SceneTree


func _init() -> void:
	var parsed := _parse_args()
	var game_seed: int = parsed["seed"]
	var output_path: String = parsed["output"]

	var result := CombatResolver.run_seeded_smoke_duel(game_seed)

	var written_path := DuelLogExporter.write_result(
		game_seed,
		result,
		attacker.id,
		defender.id,
		output_path
	)
	if written_path == "":
		push_error("Failed to write duel CSV")
		quit(1)
		return

	print("Duel CSV written to: %s" % written_path)
	print("Winner: %s | Rounds: %d" % [
		result.get("winner_id", ""),
		result.get("log", []).size(),
	])
	quit(0)


func _parse_args() -> Dictionary:
	var game_seed := 42
	var output_path := ""
	var args := OS.get_cmdline_user_args()
	var index := 0
	while index < args.size():
		var arg: String = args[index]
		if arg == "--seed" and index + 1 < args.size():
			game_seed = int(args[index + 1])
			index += 2
			continue
		if arg == "--output" and index + 1 < args.size():
			output_path = args[index + 1]
			index += 2
			continue
		index += 1
	if output_path == "":
		output_path = DuelLogExporter.default_output_path(game_seed)
	return {"seed": game_seed, "output": output_path}
