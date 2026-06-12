class_name TestStrategicCardDisplay
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_format_card_line(test_assert)
	_test_format_hand_lines(test_assert)


static func _test_format_card_line(test_assert: TestAssert) -> void:
	var line := StrategicCardDisplayPresenter.format_card_line("lumber_camp_a1")
	test_assert.check(line.contains("age"), "card line should include age")
	test_assert.check(line.contains("cost"), "card line should include cost label")


static func _test_format_hand_lines(test_assert: TestAssert) -> void:
	var lines := StrategicCardDisplayPresenter.format_hand_lines(["lumber_camp_a1", "brickworks_a1"])
	test_assert.eq(lines.size(), 2, "hand formatter should preserve card count")
