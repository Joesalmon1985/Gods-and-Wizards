class_name ArchitectureScanner
extends RefCounted

const CORE_ROOT := "res://core"
const UI_ROOT := "res://ui"
const RNG_ALLOWLIST := "res://core/rng/game_rng.gd"

const CORE_FORBIDDEN_EXTENDS: Array[String] = [
	"extends Control",
	"extends Node2D",
	"extends Node3D",
	"extends CanvasItem",
	"extends Sprite2D",
	"extends Button",
	"extends Label",
	"extends RichTextLabel",
	"extends Timer",
]

const UI_FORBIDDEN_TOKENS: Array[String] = [
	"ActionRules",
	"ProductionRules",
	"LegalActionQuery",
	"BotPolicy",
	"BotTurnResolver",
	"SetupRules.place_city",
	"ActionRules.apply",
]


static func list_gd_files(root: String) -> Array[String]:
	var files: Array[String] = []
	_collect_gd_files(root, files)
	files.sort()
	return files


static func read_code_lines(path: String) -> Array[String]:
	var lines: Array[String] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return lines
	while not file.eof_reached():
		lines.append(file.get_line())
	return lines


static func is_comment_only_line(line: String) -> bool:
	return line.strip_edges().begins_with("#")


static func line_contains_token(line: String, token: String) -> bool:
	return token in line


static func _collect_gd_files(path: String, files: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry_name := dir.get_next()
	while entry_name != "":
		if entry_name != "." and entry_name != "..":
			var full_path := "%s/%s" % [path, entry_name]
			if dir.current_is_dir():
				_collect_gd_files(full_path, files)
			elif entry_name.ends_with(".gd"):
				files.append(full_path)
		entry_name = dir.get_next()
	dir.list_dir_end()
