class_name TestSpellCombatTimelinePresenter
extends RefCounted

const PRESENTER := "res://ui/combat/spell_combat_timeline_presenter.gd"
const REPLAY_RUN_MODE := "res://run_modes/spell_combat_replay_mode.gd"
const REPLAY_SCENE := "res://run_modes/spell_combat_replay_mode.tscn"

const FORBIDDEN_TOKENS: Array[String] = [
	"SpellCombatRules.apply",
	"SpellCombatRules.legal",
]


static func run(test_assert: TestAssert) -> void:
	_test_presenter_builds_frames_from_timeline(test_assert)
	_test_presenter_does_not_compute_damage(test_assert)
	_test_known_event_types_mapped(test_assert)
	_test_unknown_event_type_safe_skip(test_assert)
	_test_replay_scene_instantiates(test_assert)


static func _fixture_timeline() -> Array:
	return [
		{"type": "combat_start", "seed": 1, "combatant_ids": ["a", "b"]},
		{"type": "cast_start", "combatant_id": "a", "spell_id": "fire_bolt", "sim_time": 0.0},
		{"type": "spell_hit", "caster_id": "a", "target_id": "b", "damage": 5.0, "sim_time": 1.0},
		{"type": "combat_end", "winner_id": "a", "sim_time": 2.0},
	]


static func _test_presenter_builds_frames_from_timeline(test_assert: TestAssert) -> void:
	var result := SpellCombatTimelinePresenter.build_frames(_fixture_timeline())
	var frames: Array = result.get("frames", [])
	test_assert.check(frames.size() >= 3, "presenter should build view frames from timeline")


static func _test_presenter_does_not_compute_damage(test_assert: TestAssert) -> void:
	for path in [PRESENTER, REPLAY_RUN_MODE]:
		for line in ArchitectureScanner.read_code_lines(path):
			if ArchitectureScanner.is_comment_only_line(line):
				continue
			for token in FORBIDDEN_TOKENS:
				test_assert.check(
					not ArchitectureScanner.line_contains_token(line, token),
					"replay presenter must not compute combat outcomes (%s) in %s" % [token, path]
				)


static func _test_known_event_types_mapped(test_assert: TestAssert) -> void:
	for event_type in SpellCombatTimelinePresenter.KNOWN_EVENT_TYPES:
		var timeline := [{"type": event_type, "sim_time": 0.0}]
		var result := SpellCombatTimelinePresenter.build_frames(timeline)
		test_assert.eq(result.get("frames", []).size(), 1, "known type should map: %s" % event_type)


static func _test_unknown_event_type_safe_skip(test_assert: TestAssert) -> void:
	var timeline := _fixture_timeline()
	timeline.insert(2, {"type": "future_fx", "value": 1})
	var result := SpellCombatTimelinePresenter.build_frames(timeline)
	test_assert.eq(int(result.get("unknown_skipped", 0)), 1, "unknown events should be skipped safely")


static func _test_replay_scene_instantiates(test_assert: TestAssert) -> void:
	var scene: PackedScene = load(REPLAY_SCENE)
	test_assert.check(scene != null, "replay scene should load")
	var node := scene.instantiate()
	test_assert.check(node != null, "replay scene should instantiate")
	if node != null:
		node.free()
