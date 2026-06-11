class_name TestWorkspaceProjects
extends RefCounted

static func run(test_assert: TestAssert) -> void:
	var workspace_root := _workspace_root()
	test_assert.check(workspace_root != "", "should resolve workspace root from godot_game")

	test_assert.check(
		not FileAccess.file_exists("%s/project.godot" % workspace_root),
		"workspace root must not contain an active project.godot"
	)

	var active := "%s/godot_game/project.godot" % workspace_root
	test_assert.check(
		FileAccess.file_exists(active),
		"godot_game/project.godot must exist as the only active project"
	)

	_assert_donor_archived(test_assert, "%s/donor_projects/board_game_M13" % workspace_root)
	_assert_donor_archived(test_assert, "%s/donor_projects/KF_wizard_game" % workspace_root)


static func _assert_donor_archived(test_assert: TestAssert, donor_path: String) -> void:
	test_assert.check(
		not FileAccess.file_exists("%s/project.godot" % donor_path),
		"donor must not contain active project.godot: %s" % donor_path
	)
	test_assert.check(
		FileAccess.file_exists("%s/project.godot.donor.txt" % donor_path),
		"donor project should be archived as project.godot.donor.txt: %s" % donor_path
	)


static func _workspace_root() -> String:
	var godot_game := ProjectSettings.globalize_path("res://").replace("\\", "/")
	if godot_game.ends_with("/"):
		godot_game = godot_game.substr(0, godot_game.length() - 1)
	return godot_game.get_base_dir()
