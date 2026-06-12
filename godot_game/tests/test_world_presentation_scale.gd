class_name TestWorldPresentationScale
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_hex_size_centralised(test_assert)
	_test_hex_centre_spacing(test_assert)
	_test_walk_speed_formula(test_assert)
	_test_180s_forward_movement(test_assert)
	_test_camera_overview_uses_scale(test_assert)


static func _test_hex_size_centralised(test_assert: TestAssert) -> void:
	test_assert.eq(WorldPresentationScale.HEX_SIZE, 16.0, "HEX_SIZE should be 16")
	var world := BoardWorldMapper.hex_to_world(HexCoord.new(1, 0))
	test_assert.check(world.x > 20.0, "board mapper should use WorldPresentationScale HEX_SIZE")


static func _test_hex_centre_spacing(test_assert: TestAssert) -> void:
	var spacing := WorldPresentationScale.hex_centre_spacing()
	test_assert.check(abs(spacing - sqrt(3.0) * 16.0) < 0.01, "hex centre spacing should be sqrt(3)*HEX_SIZE")
	test_assert.check(abs(spacing - 27.7128) < 0.1, "hex centre spacing should be about 27.71 at scale 16")


static func _test_walk_speed_formula(test_assert: TestAssert) -> void:
	var five_hex := WorldPresentationScale.five_hex_distance()
	var speed := WorldPresentationScale.walk_speed()
	test_assert.check(abs(five_hex - 5.0 * sqrt(3.0) * 16.0) < 0.1, "five hex distance formula")
	test_assert.check(abs(speed - five_hex / 180.0) < 0.001, "walk speed should be five_hex/180")
	test_assert.check(abs(speed - 0.77) < 0.02, "walk speed should be about 0.77 u/s")


static func _test_180s_forward_movement(test_assert: TestAssert) -> void:
	var keys := WizardMovementInput.keys_from_pressed(true, false, false, false, false, false)
	var move := WizardMovementInput.compute_move_delta(keys, 180.0, -1.0, 0.0)
	var distance := move.length()
	var expected := WorldPresentationScale.five_hex_distance()
	var tolerance := expected * 0.05
	test_assert.check(
		abs(distance - expected) <= tolerance,
		"180s forward movement should cross five hex centre-spacings within 5%% (got %.2f expected %.2f)" % [distance, expected]
	)


static func _test_camera_overview_uses_scale(test_assert: TestAssert) -> void:
	var transform_data := WizardCameraRig.compute_transform(
		WizardCameraRig.Mode.BOARD_OVERVIEW,
		Vector3.ZERO,
		0.0,
		Vector3.ZERO,
		WorldPresentationScale.hex_radius() * 10.0
	)
	var position: Vector3 = transform_data.get("position", Vector3.ZERO)
	test_assert.check(position.y >= WorldPresentationScale.board_height(), "board camera height should scale with world")
