class_name BotGameSession
extends RefCounted

const DEFAULT_MAX_PLAYER_TURNS := 200

var seed: int = 0
var policy_name: String = BotTurnResolver.POLICY_HEURISTIC
var state: GameState
var event_log: EventLog
var events: Array = []
var replay_baseline: Dictionary = {}
var player_turn_count: int = 0
var finished: bool = false


static func start_four_player(game_seed: int, policy: String = BotTurnResolver.POLICY_HEURISTIC) -> BotGameSession:
	var session := BotGameSession.new()
	session.seed = game_seed
	session.policy_name = policy
	session.state = ScenarioBuilder.build_four_player_bot_game(game_seed)
	session.event_log = EventLog.new()
	session.replay_baseline = EventLogReplay.capture_baseline(session.state)

	for event in GameStartRules.start_game(session.state):
		session._record_event(event)

	return session


func advance_one_player_turn() -> Array:
	if finished:
		return []

	var turn_events := BotTurnResolver.resolve_player_turn(state, event_log, policy_name)
	for event in turn_events:
		events.append(event)

	player_turn_count += 1
	finished = _check_game_over()
	return turn_events


func run_until_finished(max_player_turns: int = DEFAULT_MAX_PLAYER_TURNS) -> void:
	while not finished and player_turn_count < max_player_turns:
		advance_one_player_turn()


func to_result() -> Dictionary:
	return {
		"seed": seed,
		"state": state,
		"events": events,
		"event_log": event_log,
		"replay_baseline": replay_baseline,
		"finished": finished,
		"winner_id": state.winner_id,
		"player_turn_count": player_turn_count,
	}


func status_line() -> String:
	var active := TurnRules.get_active_player(state)
	var name := active.display_name if active != null else "?"
	return "Seed %d | Round %d | Active %s | Turns %d%s" % [
		seed,
		state.round_number,
		name,
		player_turn_count,
		" | FINISHED" if finished else "",
	]


func _record_event(event) -> void:
	events.append(event)
	event_log.append(event)


func _check_game_over() -> bool:
	var game_over := GameOverRules.evaluate(state)
	if game_over == null:
		return false
	state.game_finished = true
	state.winner_id = game_over.winner_id
	_record_event(game_over)
	return true
