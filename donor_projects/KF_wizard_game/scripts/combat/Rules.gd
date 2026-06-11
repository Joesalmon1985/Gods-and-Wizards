extends Resource
class_name Rules

# Friendly names for UI
static var display_names := {
	&"thrust": "Thrust",
	&"swing":  "Swing",
	&"jab":    "Jab",
	&"parry":  "Parry",
	&"block":  "Block",
}

# One-way pairs from your table
# winner + WinDie (attacker of that row) + LoseDie (other side)
static var _base_pairs := {
	[&"thrust", &"swing"]: { "winner": &"thrust", "win_die": 20, "lose_die": 6 },
	[&"swing",  &"jab"  ]: { "winner": &"swing",  "win_die": 15, "lose_die": 0 },
	[&"jab",    &"parry"]: { "winner": &"jab",    "win_die": 10, "lose_die": 0 },
	[&"parry",  &"block"]: { "winner": &"parry",  "win_die": 6,  "lose_die": 0 },
	[&"block",  &"thrust"]: { "winner": &"block", "win_die": 10, "lose_die": 0 },
	[&"thrust", &"jab"  ]: { "winner": &"thrust", "win_die": 20, "lose_die": 3 },
	[&"swing",  &"parry"]: { "winner": &"swing",  "win_die": 15, "lose_die": 3 },
	[&"jab",    &"block"]: { "winner": &"jab",    "win_die": 10, "lose_die": 0 },
	[&"parry",  &"thrust"]: { "winner": &"parry", "win_die": 15, "lose_die": 0 },
	[&"block",  &"swing"]: { "winner": &"block", "win_die": 6,  "lose_die": 0 },
}

# Same-move ties: both roll this die size
static var _ties := {
	&"thrust": 10,
	&"swing":  5,
	&"jab":    3,
	&"parry":  3,
	&"block":  0,
}

# Built lookup: key "a|b" -> {a_winner:1/-1/0, a_die:int, b_die:int, label:String}
static var _pairs := {}

static func _key(a: StringName, b: StringName) -> StringName:
	return StringName(String(a) + "|" + String(b))

static func _ready_table() -> void:
	if _pairs.size() > 0:
		return
	_pairs.clear()

	# Fill directional pairs + reverse
	for key in _base_pairs.keys():
		var a: StringName = key[0]
		var b: StringName = key[1]
		var e: Dictionary = _base_pairs[key]

		var win: StringName = e["winner"]
		var wdie: int = int(e["win_die"])
		var ldie: int = int(e["lose_die"])

		# Forward (a,b)
		var a_is_win: bool = (win == a)
		var a_winner_val := 1 if a_is_win else -1
		var a_die_val := wdie if a_is_win else ldie
		var b_die_val := ldie if a_is_win else wdie

		_pairs[_key(a, b)] = {
			"a_winner": a_winner_val,
			"a_die": a_die_val,
			"b_die": b_die_val,
			"label": "%s vs %s → %s" % [name_of(a), name_of(b), name_of(win)],
		}

		# Reverse (b,a)
		var b_is_win: bool = (win == b)
		var a_winner_rev := 1 if b_is_win else -1
		var a_die_rev := wdie if b_is_win else ldie
		var b_die_rev := ldie if b_is_win else wdie

		_pairs[_key(b, a)] = {
			"a_winner": a_winner_rev,
			"a_die": a_die_rev,
			"b_die": b_die_rev,
			"label": "%s vs %s → %s" % [name_of(b), name_of(a), name_of(win)],
		}

	# Ties
	for m in _ties.keys():
		var die := int(_ties[m])
		_pairs[_key(m, m)] = {
			"a_winner": 0,
			"a_die": die,
			"b_die": die,
			"label": "%s vs %s → tie" % [name_of(m), name_of(m)],
		}

static func name_of(move_id: StringName) -> String:
	return display_names.get(move_id, String(move_id).capitalize())

# Returns { a_winner:1/-1/0, a_die:int, b_die:int, label:String }
static func outcome(a: StringName, b: StringName) -> Dictionary:
	_ready_table()
	return _pairs.get(_key(a, b), {
		"a_winner": 0, "a_die": 0, "b_die": 0, "label": "%s vs %s" % [a, b]
	})

# 1dN roller
static func roll_die(die_sides: int, rng: RandomNumberGenerator) -> int:
	if die_sides <= 0:
		return 0
	return rng.randi_range(1, die_sides)
