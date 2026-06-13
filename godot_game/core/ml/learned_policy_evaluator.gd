class_name LearnedPolicyEvaluator
extends RefCounted

## Route B live evaluation: load TinyNeuralNetwork JSON weights and play headless episodes.


static func evaluate_macro(
	weights_path: String,
	game_seed: int,
	max_steps: int = 300,
	output_csv_path: String = ""
) -> Dictionary:
	var net := _load_network(weights_path, MacroFeatureFeaturizer.FEATURE_SIZE)
	if net == null:
		return {"error": "failed_to_load_weights", "checkpoint_loaded": false}
	var env := MacroTrainingEnv.new()
	env.reset(game_seed, BotTurnResolver.POLICY_RANDOM)
	var illegal_count := 0
	var steps := 0
	var completed := false
	var turn_capped := false
	var crashed := false
	while not env.is_game_over() and steps < max_steps:
		var player_id := env.session.get_active_player_id()
		var view := env.get_legal_action_view(player_id)
		var obs := env.get_observation(player_id)
		var mask := _compact_mask(view)
		var logits := net.forward(MacroFeatureFeaturizer.extract(obs))
		var action_index := net.choose_action_index(logits, mask)
		var action: GameAction = null
		if action_index >= 0 and action_index < view.action_ids.size() and view.legal_mask[action_index]:
			action = env.session.state.action_space.get_action(view.action_ids[action_index])
		if action == null:
			illegal_count += 1
			var legal := env.get_legal_actions(player_id)
			if legal.is_empty():
				break
			action = legal[0]
		var result := env.step(action)
		steps += 1
		if bool(result.get("done", false)):
			completed = true
			break
	if not env.is_game_over() and steps >= max_steps:
		turn_capped = true
	var state := env.session.state
	var report := {
		"checkpoint_loaded": true,
		"checkpoint_path": ExportPathResolver.resolve(weights_path),
		"observation_supplied": true,
		"legal_mask_supplied": true,
		"seed": game_seed,
		"steps": steps,
		"illegal_action_count": illegal_count,
		"completed_episode": completed,
		"turn_capped": turn_capped,
		"crashed": crashed,
		"breach_count": state.breach_count,
		"victory_points": _vp_for_player(state, 0),
		"winner_id": state.winner_id,
		"game_finished": state.game_finished,
	}
	if output_csv_path != "":
		_write_macro_eval_csv(output_csv_path, report)
	return report


static func evaluate_micro(
	weights_path: String,
	game_seed: int,
	loadout_a: String = "hero_patrol",
	loadout_b: String = "demon_breach",
	max_steps: int = 200,
	output_csv_path: String = ""
) -> Dictionary:
	var net := _load_network(weights_path, MicroCombatFeatureFeaturizer.FEATURE_SIZE)
	if net == null:
		return {"error": "failed_to_load_weights", "checkpoint_loaded": false}
	var env := MicroCombatTrainingEnv.new()
	env.reset(game_seed, loadout_a, loadout_b)
	var illegal_count := 0
	var steps := 0
	var completed := false
	while not env.is_done() and steps < max_steps:
		var obs := env.session.observe()
		var mask := env.build_legal_mask()
		var loadout: CombatantSpellLoadout = env.session.get_active_combatant()["loadout"]
		var logits := net.forward(MicroCombatFeatureFeaturizer.extract(obs))
		var action_index := net.choose_action_index(logits, mask)
		var spell_id := SpellCombatRules.PASS_SPELL_ID
		if action_index >= 0 and action_index < mask.size() and mask[action_index]:
			spell_id = loadout.spell_ids[action_index]
		else:
			illegal_count += 1
		env.step(spell_id)
		steps += 1
		if env.is_done():
			completed = true
			break
	var report := {
		"checkpoint_loaded": true,
		"checkpoint_path": ExportPathResolver.resolve(weights_path),
		"observation_supplied": true,
		"legal_mask_supplied": true,
		"seed": game_seed,
		"loadout_a": loadout_a,
		"loadout_b": loadout_b,
		"steps": steps,
		"illegal_action_count": illegal_count,
		"completed": completed,
		"winner_id": env.session.winner_id if env.session != null else "",
	}
	if output_csv_path != "":
		_write_micro_eval_csv(output_csv_path, report)
	return report


static func _load_network(path: String, expected_input: int) -> TinyNeuralNetwork:
	var resolved := ExportPathResolver.resolve(path)
	var file := FileAccess.open(resolved, FileAccess.READ)
	if file == null:
		push_error("Cannot open weights: %s" % path)
		return null
	var text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return null
	var net := TinyNeuralNetwork.from_dict(data)
	if net.input_size != expected_input:
		push_warning("Weight input_size %d != expected %d" % [net.input_size, expected_input])
	return net


static func _compact_mask(view: LegalActionView) -> Array:
	var bits: Array = []
	for i in range(view.legal_mask.size()):
		bits.append(view.legal_mask[i])
	return bits


static func _vp_for_player(state: GameState, player_id: int) -> int:
	for player in state.players:
		if player.id == player_id:
			return player.victory_points
	return 0


static func _write_macro_eval_csv(path: String, report: Dictionary) -> void:
	var csv := (
		"checkpoint_loaded,observation_supplied,legal_mask_supplied,seed,steps,illegal_action_count,completed_episode,turn_capped,crashed,breach_count,victory_points,winner_id,game_finished\n"
		+ "%s,%s,%s,%d,%d,%d,%s,%s,%s,%d,%d,%d,%s\n" % [
			str(report.get("checkpoint_loaded", false)).to_lower(),
			str(report.get("observation_supplied", false)).to_lower(),
			str(report.get("legal_mask_supplied", false)).to_lower(),
			int(report.get("seed", 0)),
			int(report.get("steps", 0)),
			int(report.get("illegal_action_count", 0)),
			str(report.get("completed_episode", false)).to_lower(),
			str(report.get("turn_capped", false)).to_lower(),
			str(report.get("crashed", false)).to_lower(),
			int(report.get("breach_count", 0)),
			int(report.get("victory_points", 0)),
			int(report.get("winner_id", -1)),
			str(report.get("game_finished", false)).to_lower(),
		]
	)
	ExportPathResolver.write_text(path, csv)


static func _write_micro_eval_csv(path: String, report: Dictionary) -> void:
	var csv := (
		"checkpoint_loaded,observation_supplied,legal_mask_supplied,seed,loadout_a,loadout_b,steps,illegal_action_count,completed,winner_id\n"
		+ "%s,%s,%s,%d,%s,%s,%d,%d,%s,%s\n" % [
			str(report.get("checkpoint_loaded", false)).to_lower(),
			str(report.get("observation_supplied", false)).to_lower(),
			str(report.get("legal_mask_supplied", false)).to_lower(),
			int(report.get("seed", 0)),
			str(report.get("loadout_a", "")),
			str(report.get("loadout_b", "")),
			int(report.get("steps", 0)),
			int(report.get("illegal_action_count", 0)),
			str(report.get("completed", false)).to_lower(),
			str(report.get("winner_id", "")),
		]
	)
	ExportPathResolver.write_text(path, csv)
