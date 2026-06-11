# Headless 4-player bot simulation with CSV playthrough export.
# Example:
#   godot --headless --path "<godot_game>" -s res://run_modes/run_headless_bot_game.gd -- --seed 42 --max-turns 200

extends SceneTree


func _init() -> void:
	var parsed := _parse_args()
	var game_seed: int = parsed["seed"]
	var max_turns: int = parsed["max_turns"]
	var output_path: String = parsed["output"]

	var session := BotGameSession.start_four_player(game_seed)
	session.run_until_finished(max_turns)

	var written_path := PlaythroughCsvExporter.write_session(session, game_seed, output_path)
	if written_path == "":
		push_error("Failed to write playthrough CSV")
		quit(1)
		return

	print("Playthrough CSV written to: %s" % written_path)
	print("Finished: %s | Player turns: %d | Winner: %s" % [
		session.finished,
		session.player_turn_count,
		session.state.winner_id,
	])
	quit(0)


func _parse_args() -> Dictionary:
	var game_seed := 42
	var max_turns := BotGameSession.DEFAULT_MAX_PLAYER_TURNS
	var output_path := ""
	var args := OS.get_cmdline_user_args()
	var index := 0
	while index < args.size():
		var arg: String = args[index]
		if arg == "--seed" and index + 1 < args.size():
			game_seed = int(args[index + 1])
			index += 2
			continue
		if arg == "--max-turns" and index + 1 < args.size():
			max_turns = int(args[index + 1])
			index += 2
			continue
		if arg == "--output" and index + 1 < args.size():
			output_path = args[index + 1]
			index += 2
			continue
		index += 1
	return {"seed": game_seed, "max_turns": max_turns, "output": output_path}
