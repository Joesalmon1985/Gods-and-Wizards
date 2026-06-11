class_name CombatRules
extends RefCounted

static var display_names := {
	&"thrust": "Thrust",
	&"swing": "Swing",
	&"jab": "Jab",
	&"parry": "Parry",
	&"block": "Block",
}

static var _base_pairs := {
	[&"thrust", &"swing"]: {"winner": &"thrust", "win_die": 20, "lose_die": 6},
	[&"swing", &"jab"]: {"winner": &"swing", "win_die": 15, "lose_die": 0},
	[&"jab", &"parry"]: {"winner": &"jab", "win_die": 10, "lose_die": 0},
	[&"parry", &"block"]: {"winner": &"parry", "win_die": 6, "lose_die": 0},
	[&"block", &"thrust"]: {"winner": &"block", "win_die": 10, "lose_die": 0},
	[&"thrust", &"jab"]: {"winner": &"thrust", "win_die": 20, "lose_die": 3},
	[&"swing", &"parry"]: {"winner": &"swing", "win_die": 15, "lose_die": 3},
	[&"jab", &"block"]: {"winner": &"jab", "win_die": 10, "lose_die": 0},
	[&"parry", &"thrust"]: {"winner": &"parry", "win_die": 15, "lose_die": 0},
	[&"block", &"swing"]: {"winner": &"block", "win_die": 6, "lose_die": 0},
}

static var _ties := {
	&"thrust": 10,
	&"swing": 5,
	&"jab": 3,
	&"parry": 3,
	&"block": 0,
}

static var _pairs: Dictionary = {}


static func name_of(move_id: StringName) -> String:
	return display_names.get(move_id, String(move_id).capitalize())


static func outcome(a: StringName, b: StringName) -> Dictionary:
	_ready_table()
	return _pairs.get(_pair_key(a, b), {
		"a_winner": 0,
		"a_die": 0,
		"b_die": 0,
		"label": "%s vs %s" % [a, b],
	})


static func roll_damage(die_sides: int, rng: GameRng) -> int:
	return rng.roll_die(die_sides)


static func _pair_key(a: StringName, b: StringName) -> String:
	return "%s|%s" % [a, b]


static func _ready_table() -> void:
	if not _pairs.is_empty():
		return
	_pairs.clear()
	for key in _base_pairs.keys():
		var a: StringName = key[0]
		var b: StringName = key[1]
		var entry: Dictionary = _base_pairs[key]
		var winner: StringName = entry["winner"]
		var wdie: int = int(entry["win_die"])
		var ldie: int = int(entry["lose_die"])
		var a_is_win := winner == a
		_pairs[_pair_key(a, b)] = {
			"a_winner": 1 if a_is_win else -1,
			"a_die": wdie if a_is_win else ldie,
			"b_die": ldie if a_is_win else wdie,
			"label": "%s vs %s" % [name_of(a), name_of(b)],
		}
		var b_is_win := winner == b
		_pairs[_pair_key(b, a)] = {
			"a_winner": 1 if b_is_win else -1,
			"a_die": wdie if b_is_win else ldie,
			"b_die": ldie if b_is_win else wdie,
			"label": "%s vs %s" % [name_of(b), name_of(a)],
		}
	for move in _ties.keys():
		var die := int(_ties[move])
		_pairs[_pair_key(move, move)] = {
			"a_winner": 0,
			"a_die": die,
			"b_die": die,
			"label": "%s vs %s tie" % [name_of(move), name_of(move)],
		}
