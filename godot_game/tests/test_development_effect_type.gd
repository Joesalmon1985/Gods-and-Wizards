class_name TestDevelopmentEffectType
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_test_known_effect_types(test_assert)
	_test_unknown_rejected(test_assert)


static func _test_known_effect_types(test_assert: TestAssert) -> void:
	var known := DevelopmentEffectType.all_known()
	test_assert.check(known.size() >= 14, "should expose required effect types")
	test_assert.check(DevelopmentEffectType.is_known(DevelopmentEffectType.VP_FLAT), "vp_flat known")
	test_assert.check(DevelopmentEffectType.is_known(DevelopmentEffectType.WIZARD_ACCESS), "wizard_access known")


static func _test_unknown_rejected(test_assert: TestAssert) -> void:
	test_assert.check(not DevelopmentEffectType.is_known("bespoke_card_script"), "unknown effect rejected")
