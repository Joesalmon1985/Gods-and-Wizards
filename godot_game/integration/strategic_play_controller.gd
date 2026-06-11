class_name StrategicPlayController
extends RefCounted


static func advance_until_human_or_stopped(session: BotGameSession) -> void:
	if session == null or session.finished:
		return
	session.advance_until_human_or_game_over()


static func submit_option(session: BotGameSession, options: Array, index: int) -> Array:
	var action := StrategicActionPicker.action_at_index(options, index)
	if action == null:
		return []
	return session.submit_human_action(action)
