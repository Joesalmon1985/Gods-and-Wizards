class_name SpellCombatTimelinePresenter
extends RefCounted

## Presentation-only adapter over SpellCombatSession timelines.
## Unknown event types are skipped with a warning count (see build_frames).

const KNOWN_EVENT_TYPES: Array[String] = [
	"combat_start",
	"pass",
	"cast_start",
	"spell_hit",
	"heal_applied",
	"combatant_defeated",
	"combat_end",
]


static func build_frames(timeline: Array) -> Dictionary:
	var frames: Array = []
	var unknown_skipped := 0
	for event in timeline:
		if not (event is Dictionary):
			unknown_skipped += 1
			continue
		var event_type := str(event.get("type", ""))
		if not KNOWN_EVENT_TYPES.has(event_type):
			unknown_skipped += 1
			continue
		frames.append({
			"type": event_type,
			"label": _label_for_event(event),
			"payload": event.duplicate(true),
		})
	return {
		"frames": frames,
		"unknown_skipped": unknown_skipped,
	}


static func summary_text(timeline: Array) -> String:
	var built := build_frames(timeline)
	var lines: PackedStringArray = ["Combat timeline (%d frames):" % built["frames"].size()]
	for frame in built["frames"]:
		lines.append("  • %s" % frame.get("label", frame.get("type", "?")))
	if int(built.get("unknown_skipped", 0)) > 0:
		lines.append("  (skipped %d unknown events)" % int(built["unknown_skipped"]))
	return "\n".join(lines)


static func _label_for_event(event: Dictionary) -> String:
	match str(event.get("type", "")):
		"combat_start":
			return "Combat started"
		"pass":
			return "%s passes" % event.get("combatant_id", "?")
		"cast_start":
			return "%s casts %s" % [event.get("combatant_id", "?"), event.get("spell_id", "?")]
		"spell_hit":
			return "%s hits %s for %s damage" % [
				event.get("caster_id", "?"),
				event.get("target_id", "?"),
				str(event.get("damage", 0)),
			]
		"heal_applied":
			return "%s heals for %s" % [event.get("combatant_id", "?"), str(event.get("heal", 0))]
		"combatant_defeated":
			return "%s defeated" % event.get("combatant_id", "?")
		"combat_end":
			return "Winner: %s" % event.get("winner_id", "?")
		_:
			return str(event.get("type", "event"))
