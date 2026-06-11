# EconomyPlayer.gd — upgraded base class for AI decision flow (Godot 4.4.x)
extends RefCounted
class_name EconomyPlayer

# -----------------------------------------------------------------------------
# PURPOSE
#  - Provide a common, pluggable turn-taking flow for all economy players.
#  - Encapsulate preferences and helper methods so subtypes (Smart/Stupid/Spiteful)
#    can override small pieces instead of rewriting the whole turn.
#  - Coordinate with Economy.gd via signals: Economy emits `turn_started(pid)`
#    and expects the player to call `eco.end_turn(player_id)` when done.
# -----------------------------------------------------------------------------

# ---- Identity & wiring -------------------------------------------------------
var player_id: int = -1
var name: String = ""
var eco: Object        # Economy.gd instance (keep untyped for flexibility)
var world: Object      # AbstractWorld.gd (or your board controller)

# ---- Debug ------------------------------------------------------------------
@export var debug_verbose: bool = true
@export var debug_setup_verbose: bool = false
@export var debug_setup_trace_count: int = 999999  # how many candidates to print per step

# debug capture for diversity roll
var _dbg_last_div_roll: int = 0
var _dbg_last_div_sum: float = 0.0

# ---- Preferences (weights) --------------------------------------------------
# Tune these in subclasses to create behaviours.
# Larger value = stronger preference.
@export var w_build_now_over_expand: float = 5   # prefer building now vs. placing roads just to unlock sites
@export var w_diversity_over_quantity: float = 5 # prefer diverse resource mix at a site
@export var w_city_over_settlement: float = 5    # prefer city upgrades if affordable
@export var w_need_over_trade_value: float = 5   # in trades, prefer what we need vs. objective value
@export var w_cooperation: float = 5             # positive: avoid harmful/blocking moves, accept helpful trades

# Risk/tempo knobs
@export var max_actions_per_turn: int = 3          # safety valve so AIs don't loop forever
@export var consider_top_k_sites: int = 6          # restrict site search for speed

signal turn_finished(pid: int)

# --- add near top of EconomyPlayer.gd (fields) ---
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()



# ---- Resource costs (fallbacks; eco can override with eco.get_cost(kind)) ---
var COSTS := {
	"ROAD": {"BRICK":1, "WOOD":1},
	"SETTLEMENT": {"BRICK":1, "WOOD":1, "WHEAT":1, "SHEEP":1},
	"CITY": {"WHEAT":2, "ORE":3},
}



func _edge_endpoints(e_key: Vector2i) -> Dictionary:
	# Preferred explicit API
	if world and world.has_method("edge_endpoints"):
		var res: Variant = world.edge_endpoints(e_key)
		if typeof(res) == TYPE_DICTIONARY:
			var d: Dictionary = res
			if d.has("a") and d.has("b") and typeof(d["a"]) == TYPE_VECTOR2I and typeof(d["b"]) == TYPE_VECTOR2I:
				return d

	# Common internal map: _e_by_key -> RoadSpaceModel with exported a/b
	if world and typeof(world.get("_e_by_key")) == TYPE_DICTIONARY:
		var e_map: Dictionary = world.get("_e_by_key")
		var m: Variant = null
		if e_map.has(e_key):
			m = e_map.get(e_key)

		# If it’s a Resource-like object with a/b, try to fetch via get()
		if m != null:
			var a_v: Variant = null
			var b_v: Variant = null
			if m is Object and (m as Object).has_method("get"):
				a_v = (m as Object).get("a")
				b_v = (m as Object).get("b")
			# Some projects expose fields directly; try property access as a fallback
			if a_v == null and b_v == null and m is Object:
				# Silently ignore if not present
				pass
			if typeof(a_v) == TYPE_VECTOR2I and typeof(b_v) == TYPE_VECTOR2I:
				return { "a": a_v as Vector2i, "b": b_v as Vector2i }

	# Last resort: unknown
	return {}

func _do_turn() -> void:
	if debug_verbose: print("[", name, "][INV before]", _get_inventory())
	# 1) city
	if _try_upgrade_city_simple(): return _end_turn()
	# 2) settlement
	if _try_build_settlement_simple(): return _end_turn()
	# 3) road
	if _try_build_road_towards_best(): return _end_turn()
	_end_turn()


# Returns one legal setup-road key touching v_key, or Vector2i.ZERO if none.
func _setup_pick_adjacent_road(world, pid: int, v_key: Vector2i) -> Vector2i:
	# Your AbstractWorld wants (pid, vertex_key)
	var touching_any: Array = world.probe_road_options_from_vertex(pid, v_key)

	var buildable: Array[Vector2i] = []
	var touching_count: int = 0

	for raw in touching_any:
		var e_key: Vector2i = _edge_key_from_probe(world, raw)
		if e_key == Vector2i.ZERO:
			print("[SETUP-ROAD][WARN] unexpected probe item: ", raw)
			continue
		touching_count += 1

		var ok_here: bool
		# Prefer the probe’s own legality if it’s provided
		if raw is Dictionary and raw.has("can_setup"):
			ok_here = bool(raw["can_setup"])
		else:
			ok_here = world.can_place_road(pid, e_key, true)  # setup = ignore connectivity

		if ok_here:
			buildable.append(e_key)

	print("[AI %d][SETUP] road step: touching=%d buildable=%d" % [pid, touching_count, buildable.size()])

	if buildable.is_empty():
		return Vector2i.ZERO
	return buildable[0]   # deterministic; change to pick_random() if you want


# Parse "(x, y)" strings safely in Godot 4.
func _vec2i_from_paren_string(s: String) -> Vector2i:
	var t: String = s.strip_edges()
	if t.begins_with("(") and t.ends_with(")"):
		t = t.substr(1, t.length() - 2) # remove surrounding parens
	var parts: PackedStringArray = t.split(",")
	if parts.size() >= 2:
		var xs: String = parts[0].strip_edges()
		var ys: String = parts[1].strip_edges()
		return Vector2i(int(xs), int(ys))
	return Vector2i.ZERO


# --- Utility: normalize whatever the probe returns into a Vector2i edge key ---
func _edge_key_from_probe(world, raw: Variant) -> Vector2i:
	if raw is Vector2i:
		return raw

	# Your probe returns a Dictionary like:
	# { edge: Vector2i, can_setup: bool, can_normal: bool, a: Vector2i, b: Vector2i, occupied_by: int, ... }
	if raw is Dictionary:
		if raw.has("edge"):
			var ek = raw["edge"]
			if ek is Vector2i:
				return ek
			if ek is Array and ek.size() >= 2:
				return Vector2i(int(ek[0]), int(ek[1]))
			if ek is String:
				return _vec2i_from_paren_string(ek)

	# Other shapes we’ll try to coerce
	if raw is Array and raw.size() >= 2:
		return Vector2i(int(raw[0]), int(raw[1]))
	if raw is PackedInt32Array and raw.size() >= 2:
		return Vector2i(int(raw[0]), int(raw[1]))
	if raw is PackedInt64Array and raw.size() >= 2:
		return Vector2i(int(raw[0]), int(raw[1]))
	if raw is String:
		return _vec2i_from_paren_string(raw)

	# Possibly an edge id -> ask world if it can map for us
	if raw is int:
		if world.has_method("edge_key_from_id"):
			return world.edge_key_from_id(raw)
		if world.has_method("get_edge_key"):
			return world.get_edge_key(raw)

	return Vector2i.ZERO





func _setup_place_adjacent_road(world, pid: int, v_key: Vector2i) -> void:
	var e_key: Vector2i = _setup_pick_adjacent_road(world, pid, v_key)
	if e_key == Vector2i():
		print("[AI %d][SETUP] no adjacent road options from %s" % [pid, v_key])
		return

	# Be explicit about types so the compiler doesn't need to infer.
	var can_setup: bool = world.can_place_road(pid, e_key, true)
	var can_normal: bool = world.can_place_road(pid, e_key, false)
	print("[SETUP-ROAD][DBG] e=%s can_setup=%s can_normal=%s" % [e_key, can_setup, can_normal])

	# Setup build = ignore connectivity; only occupancy blocks.
	var placed_ok: bool = world.place_road(pid, e_key, true)
	print("[AI %d][SETUP] place_road @%s -> %s" % [pid, e_key, placed_ok])


# Choose the first legal road edge touching the just-placed settlement.
# Typed for 4.4.1 to avoid Variant warnings.


func _can_place_setup_now(v: Vector2i) -> bool:
	if world == null:
		return false

	# 1) Dedicated setup API
	if world.has_method("can_place_settlement_setup"):
		var ok_setup: bool = world.can_place_settlement_setup(player_id, v)
		if ok_setup:
			return true

	# 2) Main API with both flags
	if world.has_method("can_place_settlement"):
		var ok_false: bool = world.can_place_settlement(player_id, v, false)
		if ok_false:
			return true
		var ok_true: bool = world.can_place_settlement(player_id, v, true)
		if ok_true:
			return true

	# 3) Soft fallback (occupancy + distance rule)
	if world.has_method("is_vertex_occupied") and world.has_method("adjacent_vertices"):
		if world.is_vertex_occupied(v):
			return false
		var neigh: Array = world.adjacent_vertices(v)
		for n in neigh:
			if typeof(n) == TYPE_VECTOR2I:
				var nv: Vector2i = (n as Vector2i)
				if world.is_vertex_occupied(nv):
					return false
		return true

	return false

func _place_settlement_setup(v: Vector2i) -> bool:
	if world == null:
		return false

	# Try main API with both flags
	if world.has_method("can_place_settlement") and world.has_method("place_settlement"):
		var ok_false: bool = world.can_place_settlement(player_id, v, false)
		if ok_false:
			var placed_false: bool = world.place_settlement(player_id, v, false)
			if placed_false:
				return true
		var ok_true: bool = world.can_place_settlement(player_id, v, true)
		if ok_true:
			var placed_true: bool = world.place_settlement(player_id, v, true)
			if placed_true:
				return true


	return false


func get_candidate_settlement_vertices(ignore_distance_rule: bool) -> Array:
	if world == null:
		if debug_setup_verbose:
			print("[", name, "][SETUP] world=null; no candidates")
		return []

	if world.has_method("list_candidate_settlement_vertices"):
		var arr1: Array = world.list_candidate_settlement_vertices(player_id, ignore_distance_rule)
		if debug_setup_verbose:
			print("[", name, "][SETUP] candidates via list_candidate_settlement_vertices(ignore_distance_rule=", ignore_distance_rule, ") -> ", arr1.size())
		return arr1

	# Fallback: enumerate all vertex keys and filter by can_place_settlement
	var vmap: Variant = world.get("_v2d_by_key")
	if typeof(vmap) == TYPE_DICTIONARY:
		var keys: Array = (vmap as Dictionary).keys()
		var filtered: Array = []
		for v in keys:
			var vv: Vector2i = v
			var ok := false
			if world.has_method("can_place_settlement"):
				ok = world.can_place_settlement(player_id, vv, ignore_distance_rule)
			elif world.has_method("can_place_settlement_setup"):
				# if only setup-version exists, it’s the best we can do
				ok = world.can_place_settlement_setup(player_id, vv)
			if ok:
				filtered.append(vv)
		if debug_setup_verbose:
			print("[", name, "][SETUP] fallback filter via can_place_settlement -> ", filtered.size())
		return filtered

	if debug_setup_verbose:
		print("[", name, "][SETUP] no candidate API on world; returning []")
	return []

func get_candidate_setup_settlement_vertices() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if world == null:
		if debug_setup_verbose:
			print("[", name, "][SETUP] world=null; no setup candidates")
		return out

	# Base list (typed)
	var base: Array[Vector2i] = []
	if world.has_method("list_setup_legal_vertices"):
		var r: Variant = world.list_setup_legal_vertices()
		if typeof(r) == TYPE_ARRAY:
			var arr: Array = (r as Array)
			for it in arr:
				if typeof(it) == TYPE_VECTOR2I:
					base.append(it as Vector2i)
	elif typeof(world.get("_v2d_by_key")) == TYPE_DICTIONARY:
		var vmap: Dictionary = (world.get("_v2d_by_key") as Dictionary)
		for k in vmap.keys():
			if typeof(k) == TYPE_VECTOR2I:
				base.append(k as Vector2i)

	# Filter via robust checker
	var filtered: Array[Vector2i] = []
	for v in base:
		var vv: Vector2i = v
		if _can_place_setup_now(vv):
			filtered.append(vv)

	if debug_setup_verbose:
		print("[", name, "][SETUP] candidates via base=", base.size(), " -> filtered=", filtered.size())

	# If none, probe a few to see which check is failing
	if debug_setup_verbose and filtered.is_empty() and not base.is_empty():
		var probe_count: int = min(5, base.size())
		for i in range(probe_count):
			var pv: Vector2i = base[i]
			var c1: bool = world.has_method("can_place_settlement_setup") and world.can_place_settlement_setup(player_id, pv)
			var c2: bool = world.has_method("can_place_settlement") and world.can_place_settlement(player_id, pv, false)
			var c3: bool = world.has_method("can_place_settlement") and world.can_place_settlement(player_id, pv, true)
			var occ: bool = world.has_method("is_vertex_occupied") and world.is_vertex_occupied(pv)
			print("[", name, "][SETUP][PROBE] v=", pv, " setup=", c1, " main=false=", c2, " main=true=", c3, " occupied=", occ)

	return filtered




func get_vertex_resource_profile(v: Vector2i) -> Dictionary:
	if world:
		if world.has_method("vertex_resource_profile"):
			var prof_v: Variant = world.vertex_resource_profile(v)
			if typeof(prof_v) == TYPE_DICTIONARY:
				var d: Dictionary = prof_v

				# Case A: world returns {"profile":[{resource, p, ...}, ...], "qty": ...}
				if d.has("profile") and typeof(d["profile"]) == TYPE_ARRAY:
					var flat: Dictionary = {}  # {RESOURCE: float weight}
					var arr: Array = d["profile"]
					for e in arr:
						if typeof(e) != TYPE_DICTIONARY:
							continue
						var res = e.get("resource", "")
						if res == "" or res == "DESERT":
							continue
						var p_var: Variant = e.get("p", 0.0)
						var p_val: float = 0.0
						match typeof(p_var):
							TYPE_FLOAT: p_val = p_var
							TYPE_INT:   p_val = float(p_var)
							_:          p_val = 0.0
						flat[res] = float(flat.get(res, 0.0)) + p_val
					if flat.is_empty() and debug_setup_verbose:
						print("[", name, "][SETUP][DBG] world profile had no yields for v=", v, " -> ", d)
					return flat

				# Case B: already flat (e.g., {"WOOD":0.14, ...})
				return d

			elif debug_setup_verbose:
				print("[", name, "][SETUP][DBG] vertex_resource_profile returned non-dict (", typeof(prof_v), ") for v=", v)

		# Fallback: derive simple profile from adjacency (counts only)
		if world.has_method("vertex_adjacent_resources"):
			var arr2: Array = world.vertex_adjacent_resources(v)  # e.g., ["WOOD","WHEAT",...]
			var prof2: Dictionary = {}
			for r in arr2:
				if r == "DESERT":
					continue
				prof2[r] = float(prof2.get(r, 0.0)) + 1.0
			if debug_setup_verbose:
				print("[", name, "][SETUP][DBG] vertex_adjacent_resources fallback for v=", v, " -> ", prof2)
			return prof2

	if debug_setup_verbose:
		print("[", name, "][SETUP][DBG] no resource profile API available for v=", v)
	return {}

func _dbg_explain_setup_placement(v: Vector2i) -> void:
	print("[", name, "][SETUP][DBG] explain placement @", v)
	# A) what can_place reports under normal vs setup (if available)
	if world.has_method("can_place_settlement"):
		var ok_normal := false
		# Guarded call with 3 args (pid, v, ignore_distance_rule OR setup flag)
		ok_normal = world.can_place_settlement(player_id, v, false)
		print("   can_place_settlement(pid,", v, ", false) -> ", ok_normal)
		# If your method takes 2 params in your project, comment the line above and add a 2-arg call for logging.
	if world.has_method("can_place_settlement_setup"):
		var ok_setup: bool = world.can_place_settlement_setup(player_id, v)
		print("   can_place_settlement_setup(pid,", v, ") -> ", ok_setup)

	# B) neighbor + occupied context (best-effort)
	if world.has_method("adjacent_vertices"):
		var neigh: Array = world.adjacent_vertices(v)
		print("   neighbors(", neigh.size(), ") = ", neigh)
		var any_occ: bool = false
		for n in neigh:
			var nv: Vector2i = n
			if world.has_method("is_vertex_occupied"):
				if world.is_vertex_occupied(nv):
					any_occ = true
		if world.has_method("is_vertex_occupied"):
			var self_occ: bool = world.is_vertex_occupied(v)
			print("   self occupied? ", self_occ, "  any neighbor occupied? ", any_occ)
	# C) profile
	var prof := get_vertex_resource_profile(v)
	print("   profile=", prof)


# ---- Lifecycle ---------------------------------------------------------------
func _init(id: int = -1, pname: String = "") -> void:
	player_id = id
	name = pname

func bind(e, w) -> void:
	eco = e
	world = w
	_rng.randomize()



# === Setup phase entry point (called by Economy during snake setup) ===========
func request_setup_action() -> void:
	if debug_setup_verbose:
		print("[", name, "][SETUP] request_setup_action begin; pid=", player_id)

	# --- pick a settlement site (your existing logic) ---
	var prefer_diversity: bool = _prefers_diversity_roll()
	var candidates: Array = get_candidate_setup_settlement_vertices()
	if candidates.is_empty():
		if debug_verbose: print("[", name, "] setup: no settlement candidates")
		return

	if debug_setup_verbose:
		print("[", name, "][SETUP] settlement candidates=", candidates.size())
		var produced_dbg: Dictionary = _produced_resource_set()
		print("[", name, "][SETUP] already produced (from current settlements) = ", produced_dbg.keys())
		var to_show: int = min(debug_setup_trace_count, candidates.size())
		for i in range(to_show):
			_dbg_vertex_line("cand[%d]" % i, candidates[i], produced_dbg)

	var produced: Dictionary = _produced_resource_set()
	var v_choice: Vector2i = _best_vertex_by_new_types(candidates, produced) if prefer_diversity else _best_vertex_by_quantity(candidates)

	if v_choice == Vector2i.ZERO:
		if debug_verbose: print("[", name, "] setup: could not pick settlement")
		return

	if debug_setup_verbose:
		_dbg_explain_setup_placement(v_choice)

	# --- place settlement under setup rules (your robust helper) ---
	var placed: bool = _place_settlement_setup(v_choice)
	if debug_setup_verbose:
		print("[", name, "][SETUP] place attempt @", v_choice, " -> ", placed)

	if not placed:
		if debug_verbose:
			print("[", name, "] setup: settlement placement failed @", v_choice)
		return

	if debug_verbose:
		print("[", name, "] setup: placed SETTLEMENT @", v_choice)
	_on_gain_vp_for_settlement()

	# --- single source of truth: place exactly ONE adjacent road by edge key ---
	var e_key: Vector2i = _setup_pick_adjacent_road(world, player_id, v_choice)
	if e_key == Vector2i.ZERO:
		print("[AI %d][SETUP] no adjacent road options from %s" % [player_id, v_choice])
		return

	# sanity log
	var can_setup: bool = world.can_place_road(player_id, e_key, true)
	var can_normal: bool = world.can_place_road(player_id, e_key, false)
	print("[SETUP-ROAD][DBG] e=%s can_setup=%s can_normal=%s" % [e_key, can_setup, can_normal])

	var ok: bool = world.place_road(player_id, e_key, true)  # setup: ignore connectivity
	print("[AI %d][SETUP] place_road @%s -> %s" % [player_id, e_key, ok])


func _prefers_diversity_roll() -> bool:
	var roll: int = _rng.randi_range(1, 10)
	var sum: float = w_diversity_over_quantity + float(roll)
	_dbg_last_div_roll = roll
	_dbg_last_div_sum = sum
	if debug_setup_verbose:
		print("[", name, "][SETUP] diversity roll: weight=", w_diversity_over_quantity, " + d10=", roll, " => sum=", sum, " => prefers_diversity=", sum > 10.0)
	return sum > 10.0

func _dbg_profile_to_string(prof: Dictionary) -> String:
	var parts: Array[String] = []
	for r in prof.keys():
		parts.append(str(r, ":", "%.2f" % float(prof[r])))
	return "[" + ", ".join(parts) + "]"

func _dbg_vertex_line(tag: String, v: Vector2i, produced: Dictionary) -> void:
	var prof: Dictionary = get_vertex_resource_profile(v)
	var qty: float = _quantity_value_for_vertex(v)
	var gap: float = _diversity_gap_value_for_vertex(v, produced)
	var site: float = score_vertex(v)
	var new_types: int = 0
	for r in prof.keys():
		if not produced.has(r) and float(prof[r]) > 0.0:
			new_types += 1
	print("[", name, "][SETUP] ", tag, " v=", v, " prof=", _dbg_profile_to_string(prof),
		" qty=", "%.2f" % qty, " gap=", "%.2f" % gap, " site=", "%.2f" % site,
		" new_types=", new_types)


# What do we already produce (from existing settlements)?
func _produced_resource_set() -> Dictionary:
	var produced: Dictionary = {} # res -> true
	if world and world.has_method("get_player_settlements"):
		var own: Array = world.get_player_settlements(player_id)
		for v in own:
			var prof: Dictionary = get_vertex_resource_profile(v)
			for r in prof.keys():
				if float(prof[r]) > 0.0:
					produced[r] = true
	return produced

# Raw total yield for a vertex
func _quantity_value_for_vertex(v: Vector2i) -> float:
	var prof: Dictionary = get_vertex_resource_profile(v)
	var total: float = 0.0
	for r in prof.keys():
		total += float(prof[r])
	return total

# Sum of yields for resource types we don't yet produce
func _diversity_gap_value_for_vertex(v: Vector2i, produced: Dictionary) -> float:
	var prof: Dictionary = get_vertex_resource_profile(v)
	var n: float = 0.0
	for r in prof.keys():
		if not produced.has(r) and float(prof[r]) > 0.0:
			n += float(prof[r])
	return n

func _best_vertex_by_quantity(cands: Array) -> Vector2i:
	var best: Vector2i = Vector2i.ZERO
	var best_val: float = -1e9
	for v in cands:
		var vv: Vector2i = v
		var val: float = _quantity_value_for_vertex(vv)
		# tiebreaker by diversity-sensitive site score
		if val > best_val or (is_equal_approx(val, best_val) and score_vertex(vv) > score_vertex(best)):
			best_val = val
			best = vv
	return best

func _best_vertex_by_new_types(cands: Array, produced: Dictionary) -> Vector2i:
	var best: Vector2i = Vector2i.ZERO
	var best_val: float = -1e9
	for v in cands:
		var vv: Vector2i = v
		var val: float = _diversity_gap_value_for_vertex(vv, produced)
		# tiebreaker by raw quantity
		if val > best_val or (is_equal_approx(val, best_val) and _quantity_value_for_vertex(vv) > _quantity_value_for_vertex(best)):
			best_val = val
			best = vv
	return best

# Economy connects this to its `turn_started(pid)` signal for every player.
func _on_economy_turn_started(pid: int) -> void:
	if pid != player_id:
		return
	if debug_verbose:
		print("[", name, "] turn start (pid=", player_id, ")")
	## CODE TO TAKE ACTIONS GOES HERE
	if debug_verbose: print("[EconomyPlayer] space to take action")
	call_deferred("_do_turn")  # avoid re-entrancy with Economy's emit

# ---- Main turn algorithm -----------------------------------------------------
#func _do_turn() -> void:
	#var actions_done := 0
#
	## 1) Evaluate current plan preference (build vs expand)
	#var plan: Dictionary = decide_high_level_plan()
	#if debug_verbose:
		#print("[", name, "] plan:", plan)
#
	## 2) Try to build immediately if plan says so (city > settlement when both viable)
	#if plan.get("build_now", false):
		#if _try_build_immediately():
			#actions_done += 1
			#if actions_done >= max_actions_per_turn:
				#return _end_turn()
#
	## 3) If we still want more build options, consider placing roads (expansion)
	#if plan.get("expand_first", false):
		#if _try_expand_connectivity():
			#actions_done += 1
			#if actions_done >= max_actions_per_turn:
				#return _end_turn()
#
	## 4) Re-check build after potential expansion
	#if _try_build_immediately():
		#actions_done += 1
		#if actions_done >= max_actions_per_turn:
			#return _end_turn()
#
	## 5) If still nothing to build, consider trading, then attempt build
	#if _try_trade_to_enable_build():
		#actions_done += 1
		#if _try_build_immediately():
			#actions_done += 1
			## cap actions
			#if actions_done >= max_actions_per_turn:
				#return _end_turn()
#
	## 6) End of turn
	#_end_turn()

func _end_turn() -> void:
	if debug_verbose:
		print("[", name, "] end turn")
	turn_finished.emit(player_id)  # emit is outside the debug block

# ---- Planning helpers --------------------------------------------------------
# Decide whether to focus on immediate builds or expanding connectivity.
func decide_high_level_plan() -> Dictionary:
	var can_city := _can_afford(_get_cost("CITY")) and _has_city_target()
	var can_set  := _can_afford(_get_cost("SETTLEMENT")) and _has_settlement_target()

	var build_now_score := 0.0
	if can_city:
		build_now_score += w_city_over_settlement * 1.0
	if can_set:
		build_now_score += 1.0

	var expand_score := 1.0  # some desire to unlock future sites
	# If neither build is possible, expansion becomes relatively more attractive
	if not can_city and not can_set:
		expand_score += w_build_now_over_expand * 0.25

	# Preference knob: prefer to build now if any build is available
	build_now_score *= w_build_now_over_expand

	return {
		"build_now": build_now_score >= expand_score,
		"expand_first": expand_score > build_now_score,
	}

# ---- Build attempts ----------------------------------------------------------
func _try_build_immediately() -> bool:
	# Try city first if enabled by preferences and affordable.
	if _can_afford(_get_cost("CITY")):
		var city_target := choose_city_upgrade_target()
		if city_target != Vector2i.ZERO and world.can_upgrade_city(player_id, city_target):
			if world.upgrade_city(player_id, city_target):
				if debug_verbose: print("[", name, "] built CITY at", city_target)
				_on_gain_vp_for_city()
				return true
	# Fall back to settlement
	if _can_afford(_get_cost("SETTLEMENT")):
		var v := choose_settlement_vertex(false)
		if v != Vector2i.ZERO and world.can_place_settlement(player_id, v, false):
			if world.place_settlement(player_id, v, false):
				if debug_verbose: print("[", name, "] built SETTLEMENT at", v)
				_on_gain_vp_for_settlement()
				return true
	return false

func _try_expand_connectivity() -> bool:
	# Heuristic: pick a road that most increases access to top-scoring locked sites.
	var road: Dictionary = choose_road_extension()
	if road.is_empty():
		return false
	var a: Vector2i = (road.get("a", Vector2i.ZERO) as Vector2i)
	var b: Vector2i = (road.get("b", Vector2i.ZERO) as Vector2i)
	if a != Vector2i.ZERO and b != Vector2i.ZERO and _can_afford(_get_cost("ROAD")):
		if world.can_place_road(player_id, a, b) and world.place_road(player_id, a, b):
			if debug_verbose: print("[", name, "] placed ROAD:", a, "↔", b)
			return true
	return false


func _try_trade_to_enable_build() -> bool:
	# Compute wish list based on best build opportunity we *almost* afford.
	var need := compute_trade_need()
	var offer := compute_trade_offer()
	if need.is_empty() or offer.is_empty():
		return false

	# Prefer needs over value (preference weight)
	var ok := propose_trade(offer, need)
	if ok:
		if debug_verbose: print("[", name, "] trade accepted; offer=", offer, " need=", need)
		return true
	return false

# ---- Decision primitives (override in subtypes for different personalities) -
# Return top candidate city upgrade vertex (where you already have a settlement)
func choose_city_upgrade_target() -> Vector2i:
	# Default: pick best of your existing settlements by site score
	var own_settlements: Array = world.get_player_settlements(player_id) if world.has_method("get_player_settlements") else []
	var best := Vector2i.ZERO
	var best_score := -1e9
	for v in own_settlements:
		var s := score_vertex(v)
		if s > best_score:
			best_score = s
			best = v
	return best

# Choose a settlement site; `ignore_distance_rule` is true only during setup
func choose_settlement_vertex(ignore_distance_rule: bool) -> Vector2i:
	var candidates: Array = get_candidate_settlement_vertices(ignore_distance_rule)
	if candidates.is_empty():
		return Vector2i.ZERO
	# Take top K for speed
	candidates = candidates.slice(0, min(consider_top_k_sites, candidates.size()))
	var best := Vector2i.ZERO
	var best_score := -1e9
	for v in candidates:
		var s := score_vertex(v)
		if s > best_score:
			best_score = s
			best = v
	return best


func choose_road_extension() -> Dictionary:
	# Default heuristic: ask world for recommended road (if available)
	if world.has_method("recommend_road_extension"):
		return world.recommend_road_extension(player_id)
	# Otherwise, no-op by default
	return {}

# Score a vertex by expected yield and diversity relative to current inventory
func score_vertex(v: Vector2i) -> float:
	var mix: Dictionary = get_vertex_resource_profile(v)   # {res: weight}
	var total: float = 0.0
	var distinct: int = 0
	for res in mix.keys():
		total += float(mix[res])
		if float(mix[res]) > 0.0:
			distinct += 1

	# Diversity vs quantity preference
	var diversity_score: float = float(distinct)
	var quantity_score: float = total
	var site_score: float = (w_diversity_over_quantity * diversity_score) + quantity_score

	# Nudge by what we currently need (favor resources we’re short on)
	var inv: Dictionary = _get_inventory()
	for res in mix.keys():
		var have: int = int(inv.get(res, 0))
		var need_bias: int = int(max(0, 3 - have))  # want ~3 of each baseline
		site_score += float(need_bias) * float(mix[res]) * 0.25
	return site_score


func compute_trade_need() -> Dictionary:
	# Try city then settlement; return minimal shortfall dict with explicit typing
	var need: Dictionary = _cost_shortfall(_get_cost("CITY"))
	if need.is_empty():
		return {}
	var need_set: Dictionary = _cost_shortfall(_get_cost("SETTLEMENT"))
	# Choose the smaller weighted shortfall (prefer CITY via w_city_over_settlement)
	var denom: float = w_city_over_settlement
	if denom < 0.001:
		denom = 0.001
	var need_city_weight: float = _shortfall_weight(need) / denom
	var need_set_weight: float = _shortfall_weight(need_set)
	if need_city_weight <= need_set_weight:
		return need
	return need_set


func compute_trade_offer() -> Dictionary:
	var inv: Dictionary = _get_inventory()
	var offer: Dictionary = {}
	for res in inv.keys():
		var have: int = int(inv[res])
		var keep_floor: int = 2  # keep at least 2 of everything by default
		var surplus: int = max(0, have - keep_floor)
		if surplus > 0:
			offer[res] = surplus
	return offer


func propose_trade(offer: Dictionary, need: Dictionary) -> bool:
	# If Economy exposes a trading API, use it. Provide generic fallbacks.
	if eco and eco.has_method("request_trade_bank"):
		return eco.request_trade_bank(player_id, offer, need)
	if eco and eco.has_method("request_trade_anyone"):
		return eco.request_trade_anyone(player_id, offer, need)
	return false





func _get_cost(kind: String) -> Dictionary:
	if eco and eco.has_method("get_cost"):
		var c: Variant = eco.get_cost(kind)
		if typeof(c) == TYPE_DICTIONARY:
			return (c as Dictionary)
	return COSTS.get(kind, {})


func _get_inventory() -> Dictionary:
	if eco and typeof(eco.vp_by_pid) != TYPE_NIL and eco.inventories.has(player_id):
		return eco.inventories[player_id]
	return {}

func _can_afford(cost: Dictionary) -> bool:
	var inv := _get_inventory()
	for k in cost.keys():
		if int(inv.get(k, 0)) < int(cost[k]):
			return false
	return true

func _cost_shortfall(cost: Dictionary) -> Dictionary:
	var inv := _get_inventory()
	var need := {}
	for k in cost.keys():
		var delta := int(cost[k]) - int(inv.get(k, 0))
		if delta > 0:
			need[k] = delta
	return need

func _shortfall_weight(need: Dictionary) -> float:
	var total := 0.0
	for k in need.keys():
		# Weight by trade rate if Economy exposes it
		var rate := 4
		if eco and eco.has_method("get_trade_rate"):
			rate = int(eco.get_trade_rate(player_id, k))
		total += float(need[k]) * float(rate) * (1.0 / max(0.001, w_need_over_trade_value))
	return total

func _has_city_target() -> bool:
	if world and world.has_method("get_player_settlements"):
		return (world.get_player_settlements(player_id) as Array).size() > 0
	return false

func _has_settlement_target() -> bool:
	var cands := get_candidate_settlement_vertices(false)
	return not cands.is_empty()

# VP bookkeeping hooks (override if your Economy handles VP differently)
func _on_gain_vp_for_settlement() -> void:
	if eco and eco.vp_by_pid.has(player_id):
		eco.vp_by_pid[player_id] = int(eco.vp_by_pid[player_id]) + 1
		if eco.has_method("vp_changed"):
			# if vp_changed is a signal, Economy should emit it itself; otherwise ignore
			pass

func _on_gain_vp_for_city() -> void:
	if eco and eco.vp_by_pid.has(player_id):
		eco.vp_by_pid[player_id] = int(eco.vp_by_pid[player_id]) + 1  # +1 over settlement by default
		if eco.has_method("vp_changed"):
			pass

# --- SIMPLE ACTIONS -----------------------------------------------------------
func _try_build_settlement_simple() -> bool:
	if not _can_afford(_get_cost("SETTLEMENT")):
		if debug_verbose: print("[", name, "][INV] can’t afford SETTLEMENT: ", _get_inventory())
		return false

	var v: Vector2i = choose_settlement_vertex(false)
	if v == Vector2i.ZERO:
		return false

	# Prefer Economy (handles payment)
	if eco and eco.has_method("request_build_settlement"):
		if eco.request_build_settlement(player_id, v, false):
			if debug_verbose: print("[", name, "] built SETTLEMENT at", v, " inv=", _get_inventory())
			_on_gain_vp_for_settlement()
			return true

	# Fallback to world
	if world and world.has_method("can_place_settlement") and world.has_method("place_settlement"):
		if world.can_place_settlement(player_id, v, false) and world.place_settlement(player_id, v, false):
			if debug_verbose: print("[", name, "] built SETTLEMENT at", v, " (via world) inv=", _get_inventory())
			_on_gain_vp_for_settlement()
			return true
	return false

func _try_upgrade_city_simple() -> bool:
	if not _can_afford(_get_cost("CITY")):
		if debug_verbose: print("[", name, "][INV] can’t afford CITY: ", _get_inventory())
		return false

	var v: Vector2i = choose_city_upgrade_target()
	if v == Vector2i.ZERO:
		return false

	# Prefer Economy (handles payment)
	if eco and eco.has_method("request_build_city"):
		if eco.request_build_city(player_id, v, false):
			if debug_verbose: print("[", name, "] built CITY at", v, " inv=", _get_inventory())
			_on_gain_vp_for_city()
			return true

	# Fallback to world
	if world and world.has_method("can_upgrade_city") and world.has_method("upgrade_city"):
		if world.can_upgrade_city(player_id, v) and world.upgrade_city(player_id, v):
			if debug_verbose: print("[", name, "] built CITY at", v, " (via world) inv=", _get_inventory())
			_on_gain_vp_for_city()
			return true
	return false



func _try_build_road_towards_best() -> bool:
	if not _can_afford(_get_cost("ROAD")):
		if debug_verbose: print("[", name, "][INV] can’t afford ROAD: ", _get_inventory())
		return false
	var target: Vector2i = choose_settlement_vertex(false)
	if target == Vector2i.ZERO:
		return false
# Try board recommendation
	if world and world.has_method("recommend_road_towards"):
		var rec: Variant = world.recommend_road_towards(player_id, target)
		var e_key: Vector2i = _edge_key_from_probe(world, rec)  # handles Vector2i or {edge:=...}
		if e_key != Vector2i.ZERO:
			# Prefer Economy (handles payment)
			if eco and eco.has_method("request_build_road"):
				if eco.request_build_road(player_id, e_key, false):
					if debug_verbose: print("[", name, "] placed ROAD @", e_key, " inv=", _get_inventory())
					return true
			# Fallback to world
			if world.can_place_road(player_id, e_key, false) and world.place_road(player_id, e_key, false):
				if debug_verbose: print("[", name, "] placed ROAD @", e_key, " (via world) inv=", _get_inventory())
				return true
	# Fallback chooser
	var e_choice: Vector2i = _best_placeable_edge_towards(target)
	if e_choice == Vector2i.ZERO:
		return false

	if eco and eco.has_method("request_build_road"):
		if eco.request_build_road(player_id, e_choice, false):
			if debug_verbose: print("[", name, "] placed ROAD @", e_choice, " inv=", _get_inventory())
			return true
	if world.can_place_road(player_id, e_choice, false) and world.place_road(player_id, e_choice, false):
		if debug_verbose: print("[", name, "] placed ROAD @", e_choice, " (via world) inv=", _get_inventory())
		return true

	return false


# --- ROAD CHOOSER (fallback implementation) ----------------------------------
func _best_placeable_edge_towards(target: Vector2i) -> Vector2i:
	var best_e: Vector2i = Vector2i.ZERO
	var best_d: float = 1e30

	# Start from owned settlements (that’s always in your network).
	var owned: Array = (world.get_player_settlements(player_id) if world and world.has_method("get_player_settlements") else [])
	for v in owned:
		var vv: Vector2i = v
		# Edges touching this vertex
		if not (world and world.has_method("_edges_touching_vertex")):
			continue
		var edges: Array = world._edges_touching_vertex(vv)
		for e in edges:
			var e_key: Vector2i = e
			if not world.can_place_road(player_id, e_key, false):
				continue
			var other: Vector2i = _edge_other_vertex(e_key, vv)
			if other == Vector2i.ZERO:
				continue
			var d: float = _vertex_distance(other, target)
			if d < best_d:
				best_d = d
				best_e = e_key

	return best_e



# Return the other endpoint of an edge given one endpoint (best-effort).
func _edge_other_vertex(e_key: Vector2i, known: Vector2i) -> Vector2i:
	var ep: Dictionary = _edge_endpoints(e_key)
	var a: Vector2i = ep.get("a", Vector2i.ZERO)
	var b: Vector2i = ep.get("b", Vector2i.ZERO)
	if a == known: return b
	if b == known: return a
	# Fallback: if we don’t know, pick either (still moves somewhere)
	return (a if a != Vector2i.ZERO else b)



func _vertex_distance(a: Vector2i, b: Vector2i) -> float:
	# Prefer world-provided distance if available
	if world and world.has_method("vertex_distance"):
		return float(world.vertex_distance(a, b))
	# Fallback: Euclidean in grid coords
	var dx: float = float(a.x - b.x)
	var dy: float = float(a.y - b.y)
	return sqrt(dx * dx + dy * dy)
