class_name StrategicAuditController
extends RefCounted


static func advance_one_bot_step(session: BotGameSession) -> int:
	if session == null or session.finished:
		return 0
	var before := session.events.size()
	session.advance_one_player_turn()
	return session.events.size() - before


static func advance_n_bot_steps(session: BotGameSession, step_count: int) -> int:
	if session == null or step_count <= 0:
		return 0
	var added := 0
	for _i in step_count:
		if session.finished:
			break
		added += advance_one_bot_step(session)
	return added
