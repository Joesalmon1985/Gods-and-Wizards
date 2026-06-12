class_name MacroBaselinePolicies
extends RefCounted

const POLICY_RANDOM := "random"
const POLICY_HEURISTIC := "heuristic"
const POLICY_GREEDY_VP := "greedy_vp"
const POLICY_SURVIVAL := "survival"


static func choose_action(env: MacroTrainingEnv, policy_name: String) -> GameAction:
	var player_id := env.session.get_active_player_id()
	var legal := env.get_legal_actions(player_id)
	if legal.is_empty():
		return null
	match policy_name:
		POLICY_RANDOM:
			return legal[_seeded_index(env.session.seed + env.session.player_turn_count, legal.size())]
		POLICY_HEURISTIC:
			return env.choose_policy_action()
		POLICY_GREEDY_VP:
			return _choose_greedy_vp(env, legal)
		POLICY_SURVIVAL:
			return _choose_survival(env, legal)
		_:
			return env.choose_policy_action()


static func _choose_greedy_vp(env: MacroTrainingEnv, legal: Array) -> GameAction:
	for action in legal:
		if action.kind == ActionKind.Kind.BUILD_DEVELOPMENT:
			return action
	for action in legal:
		if action.kind == ActionKind.Kind.BUILD_CITY:
			return action
	return legal[0]


static func _choose_survival(env: MacroTrainingEnv, legal: Array) -> GameAction:
	for action in legal:
		if action.kind == ActionKind.Kind.MOVE_HERO:
			return action
	for action in legal:
		if action.kind == ActionKind.Kind.END_TURN:
			return action
	return legal[0]


static func _seeded_index(seed: int, size: int) -> int:
	if size <= 0:
		return 0
	var rng := GameRng.new()
	rng.seed = seed
	return rng.randi_range(0, size - 1)
