class_name TurnReport
extends RefCounted

static func from_session(session: BotGameSession, recent_turn_count: int = 3) -> Dictionary:
	var batches := _turn_event_batches(session.events)
	var selected: Array = []
	var start := maxi(0, batches.size() - recent_turn_count)
	for i in range(start, batches.size()):
		selected.append(batches[i])

	var lines: Array[String] = []
	for batch in selected:
		lines.append_array(EventSummary.summarize_events(batch, session.state))

	if lines.is_empty():
		lines.append("No turns played yet.")

	return {
		"turn_count": session.player_turn_count,
		"lines": lines,
		"text": _format_lines(lines),
	}


static func from_turn_events(session: BotGameSession, turn_events: Array) -> Dictionary:
	var lines := EventSummary.summarize_events(turn_events, session.state)
	return {
		"turn_count": session.player_turn_count,
		"lines": lines,
		"text": _format_lines(lines),
	}


static func format_recent_log(session: BotGameSession, recent_turn_count: int = 3) -> String:
	var report := from_session(session, recent_turn_count)
	return "Recent turns:\n" + str(report.get("text", ""))


static func _turn_event_batches(events: Array) -> Array:
	var batches: Array = []
	var current: Array = []
	for event in events:
		current.append(event)
		if _is_turn_boundary(event):
			batches.append(current)
			current = []
	if not current.is_empty():
		batches.append(current)
	return batches


static func _is_turn_boundary(event) -> bool:
	if event is TurnEndedEvent:
		return true
	if event != null and event.has_method("to_dict"):
		return str(event.to_dict().get("type", "")) == "turn_ended"
	return false


static func _format_lines(lines: Array[String]) -> String:
	if lines.is_empty():
		return "  (none)"
	var formatted: PackedStringArray = []
	for line in lines:
		formatted.append("  • %s" % line)
	return "\n".join(formatted)
