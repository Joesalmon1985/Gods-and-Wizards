class_name TestTestRunner
extends RefCounted


static func run(test_assert: TestAssert) -> void:
	_test_modules_for_name_returns_single_module(test_assert)
	_test_modules_for_name_unknown_returns_empty(test_assert)
	_test_resolve_module_filter_from_args(test_assert)


static func _test_modules_for_name_returns_single_module(test_assert: TestAssert) -> void:
	var modules := TestRegistry.modules_for_name("TestHumanPlayerSession")
	test_assert.eq(modules.size(), 1, "module filter should resolve exactly one module")
	test_assert.eq(modules[0]["name"], "TestHumanPlayerSession", "module filter should preserve module name")


static func _test_modules_for_name_unknown_returns_empty(test_assert: TestAssert) -> void:
	var modules := TestRegistry.modules_for_name("TestDoesNotExist")
	test_assert.eq(modules.size(), 0, "unknown module name should return empty list")


static func _test_resolve_module_filter_from_args(test_assert: TestAssert) -> void:
	var parsed := TestRegistry.parse_cmdline_filters(["--module=TestHumanPlayerSession"])
	test_assert.eq(parsed["module"], "TestHumanPlayerSession", "parse should extract module filter")
	test_assert.eq(parsed["suite"], "", "module-only args should leave suite empty")
