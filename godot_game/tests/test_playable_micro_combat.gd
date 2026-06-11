class_name TestPlayableMicroCombat
extends RefCounted

const PLAY_RUN_MODE := "res://run_modes/spell_combat_play_mode.gd"
const PLAY_SCENE := "res://run_modes/spell_combat_play_mode.tscn"
const PICKER := "res://integration/spell_action_picker.gd"
const CONTROLLER := "res://integration/spell_combat_play_controller.gd"

const FORBIDDEN_TOKENS: Array[String] = [
	"SpellCombatRules.apply",
	"SpellCombatRules.legal",
]


static func run(test_assert: TestAssert) -> void:
	_test_deterministic_human_script(test_assert)
	_test_picker_lists_only_legal_spells(test_assert)
	_test_human_step_matches_session_step(test_assert)
	_test_play_mode_scripts_no_spell_combat_rules_in_ui(test_assert)
	_test_play_scene_instantiates(test_assert)


static func _human_script(session: SpellCombatSession, choices: Array[String]) -> void:
	var choice_index := 0
	var steps := 0
	while not session.finished and steps < 80:
		var legal := session.get_legal_spell_ids()
		var spell_id := SpellCombatRules.PASS_SPELL_ID
		if choice_index < choices.size() and legal.has(choices[choice_index]):
			spell_id = choices[choice_index]
			choice_index += 1
		elif not legal.is_empty():
			spell_id = legal[0]
		SpellCombatPlayController.step_spell(session, spell_id)
		steps += 1


static func _test_deterministic_human_script(test_assert: TestAssert) -> void:
	var choices: Array[String] = ["__pass__", "__pass__"]
	var session_a := SpellCombatSession.start_duel(321, "hero_patrol", "demon_breach")
	var session_b := SpellCombatSession.start_duel(321, "hero_patrol", "demon_breach")
	_human_script(session_a, choices)
	_human_script(session_b, choices)
	test_assert.eq(
		JSON.stringify(session_a.timeline),
		JSON.stringify(session_b.timeline),
		"same seed and human choices should produce identical timeline"
	)


static func _test_picker_lists_only_legal_spells(test_assert: TestAssert) -> void:
	var session := SpellCombatSession.start_duel(7, "hero_patrol", "demon_breach")
	var options := SpellActionPicker.build_options(session)
	test_assert.check(not options.is_empty(), "picker should expose at least pass when legal")
	for option in options:
		var spell_id: String = option.get("spell_id", "")
		test_assert.check(session.get_legal_spell_ids().has(spell_id), "picker must only list legal spells")


static func _test_human_step_matches_session_step(test_assert: TestAssert) -> void:
	var session := SpellCombatSession.start_duel(7, "hero_patrol", "demon_breach")
	var legal := session.get_legal_spell_ids()
	test_assert.check(not legal.is_empty(), "session should expose legal spells")
	var before := session.timeline.size()
	SpellCombatPlayController.step_spell(session, legal[0])
	test_assert.check(session.timeline.size() > before, "controller step should append timeline events")


static func _test_play_mode_scripts_no_spell_combat_rules_in_ui(test_assert: TestAssert) -> void:
	for path in [PLAY_RUN_MODE, PICKER, CONTROLLER]:
		for line in ArchitectureScanner.read_code_lines(path):
			if ArchitectureScanner.is_comment_only_line(line):
				continue
			for token in FORBIDDEN_TOKENS:
				test_assert.check(
					not ArchitectureScanner.line_contains_token(line, token),
					"play mode must not compute combat rules (%s) in %s" % [token, path]
				)


static func _test_play_scene_instantiates(test_assert: TestAssert) -> void:
	var scene: PackedScene = load(PLAY_SCENE)
	test_assert.check(scene != null, "play scene should load")
	var node := scene.instantiate()
	test_assert.check(node != null, "play scene should instantiate")
	if node != null:
		node.free()
