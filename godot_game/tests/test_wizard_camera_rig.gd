class_name TestWizardCameraRig
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_toggle_modes(test_assert)
	_test_wizard_mode_uses_marker(test_assert)
	_test_board_mode_uses_center(test_assert)


static func _test_toggle_modes(test_assert: TestAssert) -> void:
	var toggled := WizardCameraRig.toggle_mode(WizardCameraRig.Mode.BOARD_OVERVIEW)
	test_assert.eq(int(toggled), int(WizardCameraRig.Mode.WIZARD_MARKER), "toggle should switch to wizard mode")
	test_assert.eq(
		WizardCameraRig.mode_label(WizardCameraRig.Mode.WIZARD_MARKER),
		"Wizard",
		"wizard mode label"
	)


static func _test_wizard_mode_uses_marker(test_assert: TestAssert) -> void:
	var marker := Vector3(2.0, 0.5, 3.0)
	var transform_data := WizardCameraRig.compute_transform(
		WizardCameraRig.Mode.WIZARD_MARKER,
		marker,
		0.0,
		Vector3.ZERO,
		10.0
	)
	var position: Vector3 = transform_data.get("position", Vector3.ZERO)
	test_assert.check(position.distance_to(marker) < 5.0, "wizard camera should stay near marker")


static func _test_board_mode_uses_center(test_assert: TestAssert) -> void:
	var center := Vector3(1.0, 0.0, 2.0)
	var transform_data := WizardCameraRig.compute_transform(
		WizardCameraRig.Mode.BOARD_OVERVIEW,
		Vector3.ZERO,
		0.0,
		center,
		8.0
	)
	var look_at: Vector3 = transform_data.get("look_at", Vector3.ZERO)
	test_assert.eq(look_at, center, "board camera should look at board center")
