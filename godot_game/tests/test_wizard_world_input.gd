class_name TestWizardWorldInput
extends RefCounted

const WIZARD_WORLD_MODE := "res://run_modes/wizard_world_mode.gd"
const WIZARD_WORLD_SCENE := "res://run_modes/wizard_world_mode.tscn"


static func run(test_assert: TestAssert) -> void:
	_test_space_advances_via_explicit_handler(test_assert)
	_test_enter_and_n_advance(test_assert)
	_test_c_toggles_camera_not_space(test_assert)
	_test_p_toggles_autoplay_not_space(test_assert)
	_test_no_ui_accept_for_advance(test_assert)
	_test_overlay_buttons_focus_none(test_assert)


static func _test_space_advances_via_explicit_handler(test_assert: TestAssert) -> void:
	test_assert.eq(
		int(WizardWorldInput.action_from_keycode(KEY_SPACE)),
		int(WizardWorldInput.Action.ADVANCE),
		"KEY_SPACE should map to advance action"
	)
	var uses_input_handler := false
	for line in ArchitectureScanner.read_code_lines(WIZARD_WORLD_MODE):
		if "WizardWorldInput.action_from_keycode" in line:
			uses_input_handler = true
	test_assert.check(uses_input_handler, "wizard_world_mode should route keys through WizardWorldInput")


static func _test_enter_and_n_advance(test_assert: TestAssert) -> void:
	test_assert.eq(
		int(WizardWorldInput.action_from_keycode(KEY_ENTER)),
		int(WizardWorldInput.Action.ADVANCE),
		"KEY_ENTER should advance"
	)
	test_assert.eq(
		int(WizardWorldInput.action_from_keycode(KEY_N)),
		int(WizardWorldInput.Action.ADVANCE),
		"KEY_N should advance"
	)


static func _test_c_toggles_camera_not_space(test_assert: TestAssert) -> void:
	test_assert.eq(
		int(WizardWorldInput.action_from_keycode(KEY_C)),
		int(WizardWorldInput.Action.TOGGLE_CAMERA),
		"KEY_C should toggle camera"
	)
	test_assert.check(
		WizardWorldInput.action_from_keycode(KEY_SPACE) != WizardWorldInput.Action.TOGGLE_CAMERA,
		"KEY_SPACE must not toggle camera"
	)


static func _test_p_toggles_autoplay_not_space(test_assert: TestAssert) -> void:
	test_assert.eq(
		int(WizardWorldInput.action_from_keycode(KEY_P)),
		int(WizardWorldInput.Action.TOGGLE_AUTOPLAY),
		"KEY_P should toggle autoplay"
	)
	test_assert.check(
		WizardWorldInput.action_from_keycode(KEY_SPACE) != WizardWorldInput.Action.TOGGLE_AUTOPLAY,
		"KEY_SPACE must not toggle autoplay"
	)


static func _test_no_ui_accept_for_advance(test_assert: TestAssert) -> void:
	test_assert.check(
		not WizardWorldInput.uses_ui_accept_for_advance(),
		"wizard world must not use ui_accept for advance"
	)
	for line in ArchitectureScanner.read_code_lines(WIZARD_WORLD_MODE):
		if ArchitectureScanner.is_comment_only_line(line):
			continue
		test_assert.check(
			not ("ui_accept" in line and "_advance_simulation_step" in line),
			"wizard_world_mode must not advance via ui_accept"
		)


static func _test_overlay_buttons_focus_none(test_assert: TestAssert) -> void:
	var scene_text := FileAccess.get_file_as_string(WIZARD_WORLD_SCENE)
	test_assert.check(scene_text.contains("focus_mode = 0"), "camera button should use FOCUS_NONE")
