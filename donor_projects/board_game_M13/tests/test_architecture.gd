class_name TestArchitecture
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	_scan_core_files(test_assert)
	_scan_ui_files(test_assert)
	_check_game_simulator_headless(test_assert)


static func _scan_core_files(test_assert: TestAssert) -> void:
	for path in ArchitectureScanner.list_gd_files(ArchitectureScanner.CORE_ROOT):
		var lines := ArchitectureScanner.read_code_lines(path)
		for line in lines:
			if ArchitectureScanner.is_comment_only_line(line):
				continue
			test_assert.check(
				not ArchitectureScanner.line_contains_token(line, "res://ui/"),
				"core file must not reference ui: %s" % path
			)
			for forbidden in ArchitectureScanner.CORE_FORBIDDEN_EXTENDS:
				test_assert.check(
					not ArchitectureScanner.line_contains_token(line, forbidden),
					"core file must not use visual node type %s in %s" % [forbidden, path]
				)
			if path != ArchitectureScanner.RNG_ALLOWLIST:
				test_assert.check(
					not ArchitectureScanner.line_contains_token(line, "RandomNumberGenerator"),
					"RandomNumberGenerator must only appear in game_rng.gd: %s" % path
				)


static func _scan_ui_files(test_assert: TestAssert) -> void:
	for path in ArchitectureScanner.list_gd_files(ArchitectureScanner.UI_ROOT):
		var lines := ArchitectureScanner.read_code_lines(path)
		for line in lines:
			if ArchitectureScanner.is_comment_only_line(line):
				continue
			for forbidden in ArchitectureScanner.UI_FORBIDDEN_TOKENS:
				test_assert.check(
					not ArchitectureScanner.line_contains_token(line, forbidden),
					"ui file must not reference gameplay rules (%s) in %s" % [forbidden, path]
				)


static func _check_game_simulator_headless(test_assert: TestAssert) -> void:
	var path := "res://core/sim/game_simulator.gd"
	var lines := ArchitectureScanner.read_code_lines(path)
	var extends_refcounted := false
	for line in lines:
		if ArchitectureScanner.is_comment_only_line(line):
			continue
		if ArchitectureScanner.line_contains_token(line, "extends RefCounted"):
			extends_refcounted = true
	test_assert.check(extends_refcounted, "GameSimulator must extend RefCounted for headless use")
