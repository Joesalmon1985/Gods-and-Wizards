class_name MacroSpectatorController
extends RefCounted


static func advance_one_step(session: BotGameSession) -> void:
	if session == null or session.finished:
		return
	session.advance_one_player_turn()


static func advance_if_timer_elapsed(
	session: BotGameSession,
	timer_value: float,
	interval: float,
	delta: float
) -> bool:
	var next_timer := timer_value + delta
	if next_timer < interval:
		return false
	advance_one_step(session)
	return true
