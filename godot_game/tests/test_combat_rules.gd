class_name TestCombatRules
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var thrust_vs_swing := CombatRules.outcome(&"thrust", &"swing")
	test_assert.eq(int(thrust_vs_swing["a_winner"]), 1, "thrust should beat swing")
	test_assert.eq(int(thrust_vs_swing["a_die"]), 20, "thrust win die should be 20")

	var tie := CombatRules.outcome(&"block", &"block")
	test_assert.eq(int(tie["a_winner"]), 0, "block vs block should tie")

	var rng := GameRng.new()
	rng.seed(7)
	rng.enqueue_fixed_rolls([5])
	test_assert.eq(CombatRules.roll_damage(10, rng), 5, "combat damage should use GameRng")
