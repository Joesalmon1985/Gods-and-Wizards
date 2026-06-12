class_name StrategicAuditViewModel
extends RefCounted

const MODE_TITLE := "2D Macro Audit Mode"
const MAX_RECENT_EVENTS := 12


static func build(session: BotGameSession) -> Dictionary:
	var snapshot := BoardWorldMapper.build_snapshot(session.state, session.events)
	var summary := GameStateSummary.build(session.state, session)
	summary["title"] = MODE_TITLE
	var legal_labels := LegalActionReport.legal_action_labels(session.state)
	var report := TurnReport.from_session(session, 3)
	return {
		"title": MODE_TITLE,
		"header_text": GameStateSummary.format_header(summary),
		"scoreboard_text": GameStateSummary.format_scoreboard(summary),
		"legal_action_labels": legal_labels,
		"legal_action_count": legal_labels.size(),
		"recent_event_lines": _recent_event_lines(session),
		"recent_turn_text": str(report.get("text", "")),
		"breach_count": int(snapshot.get("breach_count", 0)),
		"total_demons": int(snapshot.get("total_demons", 0)),
		"phase": summary.get("phase", ""),
		"infection_rate": summary.get("infection_rate", 0),
		"draft_age": summary.get("draft_age", 1),
		"hero_actions_remaining": summary.get("hero_actions_remaining", {}),
		"finished": session.finished,
		"waiting_for_human": session.waiting_for_human,
	}


static func format_legal_actions(model: Dictionary) -> String:
	var labels: Array = model.get("legal_action_labels", [])
	if labels.is_empty():
		return "Legal actions: (none)"
	var lines: PackedStringArray = ["Legal actions (%d):" % labels.size()]
	for label in labels:
		lines.append("  • %s" % label)
	return "\n".join(lines)


static func format_recent_events(model: Dictionary) -> String:
	var lines: Array = model.get("recent_event_lines", [])
	if lines.is_empty():
		return "Recent events:\n  (none)"
	var formatted: PackedStringArray = ["Recent events:"]
	for line in lines:
		formatted.append("  • %s" % line)
	return "\n".join(formatted)


static func _recent_event_lines(session: BotGameSession) -> Array[String]:
	var lines: Array[String] = []
	var start := maxi(0, session.events.size() - MAX_RECENT_EVENTS)
	for i in range(start, session.events.size()):
		var event = session.events[i]
		if event == null:
			continue
		if event.has_method("to_dict"):
			var data: Dictionary = event.to_dict()
			var line := EventSummary.summarize_event_entry(
				str(data.get("type", "")),
				data,
				session.state
			)
			if line != "":
				lines.append(line)
	if lines.is_empty():
		lines.append("No events yet.")
	return lines
