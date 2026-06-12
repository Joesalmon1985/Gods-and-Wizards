class_name TrainingEvaluationHarness
extends RefCounted

const METRICS_COLUMNS: Array[String] = [
	"domain",
	"policy_name",
	"seed",
	"episodes",
	"win_rate",
	"avg_victory_points",
	"breach_loss_rate",
	"avg_turns",
	"avg_reward",
	"combat_win_rate",
	"avg_combat_steps",
]


static func evaluate_macro(
	policy_name: String,
	base_seed: int,
	episodes: int = 4,
	max_steps: int = 40
) -> Dictionary:
	var wins := 0
	var breach_losses := 0
	var total_vp := 0.0
	var total_turns := 0.0
	var total_reward := 0.0
	for episode in range(episodes):
		var env := MacroTrainingEnv.new()
		env.reset(base_seed + episode, BotTurnResolver.POLICY_HEURISTIC)
		var episode_reward := 0.0
		var steps := 0
		while not env.is_game_over() and steps < max_steps:
			var player_id := env.session.get_active_player_id()
			var action := MacroBaselinePolicies.choose_action(env, policy_name)
			if action == null:
				break
			var result := env.step(action)
			episode_reward += float(result.get("rewards", {}).get(player_id, 0.0))
			steps += 1
		var summary := env.get_summary()
		total_turns += float(summary.get("player_turn_count", 0))
		total_reward += episode_reward
		var winner_id := int(summary.get("winner_id", -1))
		if winner_id == 0:
			wins += 1
		if str(summary.get("outcome_reason", "")).contains("breach"):
			breach_losses += 1
		var vp_map: Dictionary = summary.get("vp_by_player", {})
		total_vp += float(vp_map.get(0, 0))
	return {
		"domain": "macro",
		"policy_name": policy_name,
		"seed": base_seed,
		"episodes": episodes,
		"win_rate": float(wins) / float(maxi(episodes, 1)),
		"avg_victory_points": total_vp / float(maxi(episodes, 1)),
		"breach_loss_rate": float(breach_losses) / float(maxi(episodes, 1)),
		"avg_turns": total_turns / float(maxi(episodes, 1)),
		"avg_reward": total_reward / float(maxi(episodes, 1)),
		"combat_win_rate": 0.0,
		"avg_combat_steps": 0.0,
	}


static func evaluate_micro(
	policy_name: String,
	base_seed: int,
	episodes: int = 4,
	max_steps: int = 80
) -> Dictionary:
	var wins := 0
	var total_steps := 0.0
	var total_reward := 0.0
	for episode in range(episodes):
		var env := MicroCombatTrainingEnv.new()
		env.reset(base_seed + episode)
		var steps := 0
		var episode_reward := 0.0
		while not env.is_done() and steps < max_steps:
			var spell_id := MicroBaselinePolicies.choose_spell_id(env, policy_name)
			var result := env.step(spell_id)
			episode_reward += float(result.get("reward", 0.0))
			steps += 1
		total_steps += float(steps)
		total_reward += episode_reward
		if env.session != null and env.session.winner_id == "hero_patrol":
			wins += 1
	return {
		"domain": "micro",
		"policy_name": policy_name,
		"seed": base_seed,
		"episodes": episodes,
		"win_rate": 0.0,
		"avg_victory_points": 0.0,
		"breach_loss_rate": 0.0,
		"avg_turns": 0.0,
		"avg_reward": total_reward / float(maxi(episodes, 1)),
		"combat_win_rate": float(wins) / float(maxi(episodes, 1)),
		"avg_combat_steps": total_steps / float(maxi(episodes, 1)),
	}


static func render_metrics_csv(rows: Array) -> String:
	var lines: PackedStringArray = [",".join(METRICS_COLUMNS)]
	for row in rows:
		var values: PackedStringArray = []
		for column in METRICS_COLUMNS:
			values.append(str(row.get(column, "")))
		lines.append(",".join(values))
	return "\n".join(lines) + "\n"
