class_name GameSimulator
extends RefCounted

static func run(
	game_seed: int,
	rounds: int,
	policy_name: String = BotTurnResolver.POLICY_HEURISTIC
) -> Dictionary:
	var state := ScenarioBuilder.build_bot_ready_game(game_seed)
	var events: Array = []
	var event_log := EventLog.new()
	var replay_baseline := EventLogReplay.capture_baseline(state)

	var start_events := GameStartRules.start_game(state)
	for event in start_events:
		events.append(event)
		event_log.append(event)

	var finished := false
	for _round_index in range(rounds):
		if finished:
			break
		for _player_index in range(TurnRules.player_count(state)):
			if finished:
				break
			events.append_array(BotTurnResolver.resolve_player_turn(state, event_log, policy_name))
			finished = _append_game_over_if_needed(state, events, event_log)

	return {
		"state": state,
		"events": events,
		"event_log": event_log,
		"replay_baseline": replay_baseline,
		"finished": state.game_finished,
		"winner_id": state.winner_id,
		"snapshot": GameSnapshot.snapshot(state, events, event_log),
	}


static func _append_game_over_if_needed(state: GameState, events: Array, event_log: EventLog) -> bool:
	var game_over := GameOverRules.evaluate(state)
	if game_over == null:
		return false
	state.game_finished = true
	state.winner_id = game_over.winner_id
	events.append(game_over)
	event_log.append(game_over)
	return true
