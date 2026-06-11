# Full suite: godot --headless --path "<project>" -s res://tests/test_runner.gd
# Optional filter: ... -s res://tests/test_runner.gd -- --suite=architecture

extends SceneTree


func _init() -> void:
	var suite_filter := TestRegistry.resolve_suite_filter()
	var modules := TestRegistry.all_modules()
	if not suite_filter.is_empty():
		modules = TestRegistry.modules_for_category(suite_filter)

	var test_assert := TestAssert.new()
	var modules_run := 0
	var assertions_before := 0

	for entry in modules:
		var module_name: String = entry["name"]
		var module = entry["module"]
		var category: String = entry["category"]
		assertions_before = test_assert.assertions_run
		test_assert.begin_module(module_name)
		module.run(test_assert)
		modules_run += 1
		var module_assertions := test_assert.assertions_run - assertions_before
		if _module_failed(test_assert, module_name):
			print("[%s] %s: FAILED (%d assertions)" % [category, module_name, module_assertions])
		else:
			print("[%s] %s: passed (%d assertions)" % [category, module_name, module_assertions])

	var failed_count := test_assert.failures.size()
	var passed_assertions := test_assert.assertions_run - failed_count
	print("")
	print("Ran %d modules, %d assertions" % [modules_run, test_assert.assertions_run])
	print("Passed: %d" % passed_assertions)
	print("Failed: %d" % failed_count)

	if test_assert.has_failures():
		for failure in test_assert.failures:
			printerr("FAIL: %s" % failure)
		quit(1)
	else:
		quit(0)


func _module_failed(test_assert: TestAssert, module_name: String) -> bool:
	for failure in test_assert.failures:
		if failure.begins_with("[%s]" % module_name):
			return true
	return false
