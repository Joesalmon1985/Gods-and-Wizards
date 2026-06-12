class_name MacroTrainingReward
extends RefCounted

const PROFILE_BALANCED := "balanced"
const PROFILE_VP := "vp"
const PROFILE_SURVIVAL := "survival"

const TERMINAL_WIN := 10.0
const BREACH_PENALTY := -0.5
const DEMON_CLEAR_BONUS := 0.25


static func compute_components(
	events: Array,
	state: GameState,
	player_id: int,
	vp_before: int,
	breach_before: int
) -> Dictionary:
	var player := _player_by_id(state, player_id)
	var vp_after := player.victory_points if player != null else vp_before
	var components := {
		"vp_delta": float(vp_after - vp_before),
		"breach_delta": float(state.breach_count - breach_before),
		"terminal_win": 0.0,
		"demon_clear": 0.0,
	}
	for event in events:
		if event is DemonsClearedEvent:
			components["demon_clear"] = float(components["demon_clear"]) + DEMON_CLEAR_BONUS
	if state.game_finished and state.winner_id == player_id:
		components["terminal_win"] = TERMINAL_WIN
	return components


static func total_from_components(components: Dictionary, profile: String = PROFILE_BALANCED) -> float:
	match profile:
		PROFILE_VP:
			return float(components.get("vp_delta", 0.0)) + float(components.get("terminal_win", 0.0))
		PROFILE_SURVIVAL:
			return float(components.get("breach_delta", 0.0)) * BREACH_PENALTY + float(components.get("demon_clear", 0.0))
		_:
			return (
				float(components.get("vp_delta", 0.0))
				+ float(components.get("terminal_win", 0.0))
				+ float(components.get("breach_delta", 0.0)) * BREACH_PENALTY
				+ float(components.get("demon_clear", 0.0))
			)


static func _player_by_id(state: GameState, player_id: int) -> Player:
	for player in state.players:
		if player.id == player_id:
			return player
	return null
