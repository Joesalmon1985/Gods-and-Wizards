# Unified audit playthrough export with provenance manifest.
extends SceneTree


func _init() -> void:
	var parsed := _parse_args()
	var session := BotGameSession.start_four_player(parsed["seed"], BotTurnResolver.POLICY_HEURISTIC)
	session.run_until_finished(parsed["max_turns"])
	var rows := AuditCsvExporter.build_rows(session, parsed["git_sha"])
	var csv := AuditCsvExporter.render_csv(rows)
	if not ExportPathResolver.write_text(parsed["output"], csv):
		push_error("Failed to write audit CSV")
		quit(1)
		return
	var manifest_path := parsed["manifest"]
	if manifest_path != "":
		AuditCsvExporter.write_manifest(manifest_path, [{
			"path": ExportPathResolver.globalized(parsed["output"]),
			"seed": parsed["seed"],
			"rules_version": AuditCsvExporter.RULES_VERSION,
		}])
	print("Audit CSV written: %s" % ExportPathResolver.globalized(parsed["output"]))
	quit(0)


func _parse_args() -> Dictionary:
	var game_seed := 42
	var max_turns := 300
	var output := ""
	var manifest := ""
	var git_sha := ""
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		var arg: String = args[i]
		if arg == "--seed" and i + 1 < args.size():
			game_seed = int(args[i + 1])
			i += 2
			continue
		if arg == "--max-turns" and i + 1 < args.size():
			max_turns = int(args[i + 1])
			i += 2
			continue
		if arg == "--output" and i + 1 < args.size():
			output = args[i + 1]
			i += 2
			continue
		if arg == "--manifest" and i + 1 < args.size():
			manifest = args[i + 1]
			i += 2
			continue
		if arg == "--git-sha" and i + 1 < args.size():
			git_sha = args[i + 1]
			i += 2
			continue
		i += 1
	if output == "":
		output = "user://audit_playthrough.csv"
	return {
		"seed": game_seed,
		"max_turns": max_turns,
		"output": output,
		"manifest": manifest,
		"git_sha": git_sha,
	}
