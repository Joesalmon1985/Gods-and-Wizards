class_name TestProjectLayout
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	for path in ArchitectureScanner.list_gd_files(ArchitectureScanner.CORE_ROOT):
		var lines := ArchitectureScanner.read_code_lines(path)
		for line in lines:
			if ArchitectureScanner.is_comment_only_line(line):
				continue
			test_assert.check(
				not ArchitectureScanner.line_contains_token(line, "donor_projects"),
				"core must not reference donor projects: %s" % path
			)
