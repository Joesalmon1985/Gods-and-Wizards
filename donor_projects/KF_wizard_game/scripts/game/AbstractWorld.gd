extends RefCounted
class_name AbstractWorld

# Debug flag
var debug_verbose: bool = true


var _v2d_by_key: Dictionary = {}   # Vector2i -> SettlementSpace2D
var _e2d_by_key: Dictionary = {}   # Vector2i -> RoadSpace2D
var _built_settlement_2d: Dictionary = {}  # Vector2i -> Settlement2D
var _built_road_2d: Dictionary = {}        # Vector2i -> Road2D

signal hex_added(model: HexModel)
signal settlement_space_added(model: SettlementSpaceModel)
signal road_space_added(model: RoadSpaceModel)
signal settlement_added(model)
signal road_added(model)

const Settlement3D         := preload("res://scripts/view/Settlement3D.gd")
const City3D               := preload("res://scripts/view/City3D.gd")
const HexModel             := preload("res://scripts/model/HexModel.gd")
const SettlementSpaceModel := preload("res://scripts/model/SettlementSpaceModel.gd")
const RoadSpaceModel       := preload("res://scripts/model/RoadSpaceModel.gd")
const Hex2D                := preload("res://scripts/view/Hex2D.gd")
const SettlementSpace2D    := preload("res://scripts/view/SettlementSpace2D.gd")
const RoadSpace2D          := preload("res://scripts/view/RoadSpace2D.gd")
const Settlement2D         := preload("res://scripts/view/Settlement2D.gd")
const Road2D               := preload("res://scripts/view/Road2D.gd")
const City2D               := preload("res://scripts/view/City2D.gd")
const Port2D               := preload("res://scripts/view/Port2D.gd")
const Robber2D             := preload("res://scripts/view/Robber2D.gd")
const HexFactory           := preload("res://scripts/view/HexTile3D_Factory.gd")


# --- Cities ---
var _cities_at: Dictionary = {}              # Vector2i -> owner_id (city present at vertex)
var _built_city_2d: Dictionary = {}          # Vector2i -> City2D instance

# --- Ports ---
var ports: Array = []                        # Array of {pos: <key>, type: String, rate: int}
											 # (stub: we don't use pos yet)

# --- Robber ---
var _robber_pos: Vector2i = Vector2i.ZERO
var _robber_node: Node2D = null


var _built_city_3d: Dictionary = {}              # Vector2i -> City3D


var hexes: Array[HexModel] = []
var settlement_spaces: Array[SettlementSpaceModel] = []
var road_spaces: Array[RoadSpaceModel] = []



# fast lookup (keys are Vector2i)
var _v_by_key: Dictionary = {}  # Vector2i -> SettlementSpaceModel
var _e_by_key: Dictionary = {}  # Vector2i -> RoadSpaceModel
var _built_settlement_3d: Dictionary = {}  # Vector2i -> Settlement3D

# view targets
var _world2d: Node2D = null
var _world3d: Node3D = null

# tuning
var hex_size: float = 64.0
var hex_height_3d: float = 0.4
var ground_y: float = 0.0
const KEY_SCALE := 1000.0


# Only block when the road space is already taken.
# Return true when the edge exists and is empty.
func can_place_road(player_id: int, e_key: Vector2i, ignore_connectivity: bool = false) -> bool:
	var e := _e_by_key.get(e_key) as RoadSpaceModel
	if e == null:
		return false

	# Occupancy only: free iff occupied_by == -1
	if e.occupied_by != -1:
		return false

	# During setup we ignore connectivity (you pass true from the caller)
	if ignore_connectivity:
		return true

	# --- Normal rules below (must connect to player's network) ---

	# Adjacent to one of my settlements?
	var a := _v_by_key.get(e.a) as SettlementSpaceModel
	var b := _v_by_key.get(e.b) as SettlementSpaceModel
	if (a != null and a.occupied_by == player_id) or (b != null and b.occupied_by == player_id):
		return true

	# Adjacent to one of my roads?
	# If you have a helper list of edges-from-vertex, use that to scan neighbors.
	for neigh_key in _edges_touching_vertex(e.a):
		var neigh := _e_by_key.get(neigh_key) as RoadSpaceModel
		if neigh != null and neigh.occupied_by == player_id:
			return true
	for neigh_key in _edges_touching_vertex(e.b):
		var neigh2 := _e_by_key.get(neigh_key) as RoadSpaceModel
		if neigh2 != null and neigh2.occupied_by == player_id:
			return true

	return false




# Handy probe for logs: shows what the world thinks around a vertex
func probe_road_options_from_vertex(pid: int, v_key: Vector2i) -> Array:
	var out: Array = []
	var edges: Array = _edges_touching_vertex(v_key)
	for ee in edges:
		var m: RoadSpaceModel = _e_by_key.get(ee) as RoadSpaceModel
		var a_owner: int = -1
		var b_owner: int = -1
		if m != null:
			var a_v: SettlementSpaceModel = _v_by_key.get(m.a) as SettlementSpaceModel
			var b_v: SettlementSpaceModel = _v_by_key.get(m.b) as SettlementSpaceModel
			a_owner = a_v.occupied_by if a_v != null else -1
			b_owner = b_v.occupied_by if b_v != null else -1
		var can_norm: bool = can_place_road(pid, ee, false)
		var can_setup: bool = can_place_road(pid, ee, true)
		out.append({
			"edge": ee,
			"can_normal": can_norm,
			"can_setup": can_setup,
			"a": m.a if m != null else Vector2i(0,0),
			"b": m.b if m != null else Vector2i(0,0),
			"a_owner": a_owner,
			"b_owner": b_owner,
			"occupied_by": (m.occupied_by if m != null else -1)
		})
	print("[WORLD][PROBE] v=%s edges=%d -> %s" % [str(v_key), edges.size(), JSON.stringify(out)])
	return out


# Returns all empty edge keys touching the given vertex (for setup round).
func list_setup_buildable_roads_adjacent_to_vertex(pid: int, v_key: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var edges: Array = _edges_touching_vertex(v_key)  # Array[Vector2i]
	for e_any in edges:
		var e_key: Vector2i = e_any
		var e: RoadSpaceModel = _e_by_key.get(e_key) as RoadSpaceModel
		if e == null:
			continue
		if e.occupied_by != -1:
			continue
		# During setup we purposely skip network connectivity.
		if can_place_road(pid, e_key, true):
			result.append(e_key)
	return result


# Call this immediately after a successful settlement placement during setup.
# It places exactly one adjacent road if any are empty.
func setup_build_one_road_after_settlement(pid: int, v_key: Vector2i) -> bool:
	var opts: Array[Vector2i] = list_setup_buildable_roads_adjacent_to_vertex(pid, v_key)
	print("[World][SETUP] road options from %s = %d" % [str(v_key), opts.size()])
	if opts.is_empty():
		_probe_road_options_from_vertex(pid, v_key)
		return false
	var chosen: Vector2i = opts[0]   # or apply your own scoring/choice
	var ok: bool = place_road(pid, chosen, true)   # ignore_connectivity = true
	print("[World][SETUP] place_road(%d, %s, ignore_connectivity=true) => %s" % [pid, str(chosen), str(ok)])
	return ok


# Optional: targeted probe that prints exactly why edges are or aren’t buildable
func _probe_road_options_from_vertex(pid: int, v_key: Vector2i) -> void:
	var edges: Array = _edges_touching_vertex(v_key)  # Array[Vector2i]
	print("[DBG] edges touching %s -> %d" % [str(v_key), edges.size()])
	for e_any in edges:
		var e_key: Vector2i = e_any
		var m: RoadSpaceModel = _e_by_key.get(e_key) as RoadSpaceModel
		var a_owner: int = -1
		var b_owner: int = -1
		var a_key: Vector2i = Vector2i(0, 0)
		var b_key: Vector2i = Vector2i(0, 0)
		if m != null:
			a_key = m.a
			b_key = m.b
			var a_v: SettlementSpaceModel = _v_by_key.get(m.a) as SettlementSpaceModel
			var b_v: SettlementSpaceModel = _v_by_key.get(m.b) as SettlementSpaceModel
			a_owner = a_v.occupied_by if a_v != null else -1
			b_owner = b_v.occupied_by if b_v != null else -1
		var can_norm: bool = can_place_road(pid, e_key, false)
		var can_setup: bool = can_place_road(pid, e_key, true)
		var occ: int = (m.occupied_by if m != null else -2)
		print("  edge=%s a=%s b=%s occ=%d a_owner=%d b_owner=%d can_normal=%s can_setup=%s" %
			[str(e_key), str(a_key), str(b_key), occ, a_owner, b_owner, str(can_norm), str(can_setup)])


# --- ECON API for AI setup evaluation ---------------------------------------
func vertex_resource_profile(v_key: Vector2i) -> Dictionary:
	return _compute_vertex_resource_profile_dict(v_key)

func get_vertex_resource_profile(v_key: Vector2i) -> Dictionary:
	return _compute_vertex_resource_profile_dict(v_key)

func resource_profile_for_vertex(v_key: Vector2i) -> Dictionary:
	return _compute_vertex_resource_profile_dict(v_key)

func _compute_vertex_resource_profile_dict(v_key: Vector2i) -> Dictionary:
	var prof: Array = []     # array of 0..3 entries: {resource:String, roll:int, p:float}
	var v: SettlementSpaceModel = _v_by_key.get(v_key) as SettlementSpaceModel
	if v == null:
		return {"profile": prof, "qty": 0.0}

	# v.adjacent_hexes should be your axial coords for the 3 touching hexes
	for ax in v.adjacent_hexes:
		var h := _hex_by_axial(ax)
		if h == null: 
			continue
		var res := _res_to_string(h.resource)      # "WOOD", "BRICK", ...
		var roll := int(h.roll_number)
		var p := _roll_prob(roll)                  # 0..5/36
		prof.append({"resource": res, "axial": ax, "roll": roll, "p": p})

	var qty := 0.0
	for e in prof:
		if e.resource != "DESERT":
			qty += float(e.p)

	return {
		"profile": prof,   # <- this is the thing your AI will read
		"qty": qty         # (extras are fine; AI will ignore if it doesn’t need them)
	}

func _roll_prob(n: int) -> float:
	match n:
		2,12: return 1.0/36.0
		3,11: return 2.0/36.0
		4,10: return 3.0/36.0
		5, 9: return 4.0/36.0
		6, 8: return 5.0/36.0
		_:    return 0.0


func _dbg_id(node: Node) -> String:
	return "%s#%d" % [node.name, node.get_instance_id()]

func can_place_city(player_id: int, v_key: Vector2i) -> bool:
	# Upgrade rule: must own a settlement here; cannot already be a city.
	var v: SettlementSpaceModel = _v_by_key.get(v_key) as SettlementSpaceModel
	if v == null:
		return false
	if v.occupied_by != player_id:
		return false
	if _cities_at.has(v_key):
		return false
	return true


func get_resource_profile_for_vertex(v_key: Vector2i) -> Array:
	return _compute_vertex_resource_profile(v_key)

# Convenience helpers the AI *might* also use
func get_vertex_resource_types(v_key: Vector2i) -> Array:
	var out: Array = []
	for e in _compute_vertex_resource_profile(v_key):
		out.append(e["resource"])
	return out

func get_vertex_expected_yield(v_key: Vector2i) -> float:
	var sum := 0.0
	for e in _compute_vertex_resource_profile(v_key):
		sum += float(e["p"])
	return sum

# Internal worker
func _compute_vertex_resource_profile(v_key: Vector2i) -> Array:
	var v := _v_by_key.get(v_key) as SettlementSpaceModel
	if v == null:
		return []
	var out: Array = []
	for ax in v.adjacent_hexes:
		var h := _hex_by_axial(ax)
		if h == null:
			continue
		var p := _roll_prob(int(h.roll_number))
		out.append({
			"resource": h.resource,   # "WOOD", "BRICK", "WHEAT", "SHEEP", "ORE", "DESERT"
			"axial": ax,              # Vector2i(q,r)
			"roll": int(h.roll_number),
			"p": p                    # expected yield weight (0..5/36)
		})
	return out




func place_city(player_id: int, v_key: Vector2i) -> bool:
	if not can_place_city(player_id, v_key):
		return false

	# Mark upgrade in state
	_cities_at[v_key] = player_id

	# Swap visuals: remove settlement visuals, add city visuals (2D+3D if targets exist)
	_upgrade_vertex_visuals_to_city(player_id, v_key)

	# (No need to change v.occupied_by; ownership remains)
	# (No spacing/legality change needed; upgrading doesn’t open or close spaces)
	return true


func _spawn_built_settlement_3d(v: SettlementSpaceModel) -> void:
	if _world3d == null: return
	if v.occupied_by == -1: return
	if _built_settlement_3d.has(v.key): return

	var s := Settlement3D.new()

	# ✅ Set faction BEFORE adding to the scene so Spawner sees the right value
	s.faction = v.occupied_by

	var p2: Vector2 = v.position
	var y := ground_y + hex_height_3d + 0.01
	s.position = Vector3(p2.x, y, p2.y)

	_world3d.add_child(s)
	_built_settlement_3d[v.key] = s

	s.apply_owner(_player_color(v.occupied_by))


func is_city_at(corner: Vector2i) -> bool:
	return _cities_at.has(corner)


func owner_at_vertex(corner: Vector2i) -> int:
	var v: SettlementSpaceModel = _v_by_key.get(corner) as SettlementSpaceModel
	if v != null and v.occupied_by != -1:
		return v.occupied_by
	return -1

func _spawn_built_city_2d(v: SettlementSpaceModel) -> void:
	if _world2d == null: return
	if v.occupied_by == -1: return
	if _built_city_2d.has(v.key): return
	var c := City2D.new()
	c.position = v.position
	_world2d.add_child(c)
	_built_city_2d[v.key] = c
	c.apply_owner(_player_color(v.occupied_by))


func _spawn_built_city_3d(v: SettlementSpaceModel) -> void:
	if _world3d == null: return
	if v.occupied_by == -1: return
	if _built_city_3d.has(v.key): return

	var c := City3D.new()
	c.faction = v.occupied_by   # mirror Settlement3D’s usage

	var p2: Vector2 = v.position
	var y := ground_y + hex_height_3d + 0.01
	c.position = Vector3(p2.x, y, p2.y)

	_world3d.add_child(c)
	_built_city_3d[v.key] = c
	c.apply_owner(_player_color(v.occupied_by))


func _upgrade_vertex_visuals_to_city(player_id: int, v_key: Vector2i) -> void:
	# Remove settlement visuals if present
	if _built_settlement_2d.has(v_key):
		var s2: Node2D = _built_settlement_2d[v_key]
		if is_instance_valid(s2): s2.queue_free()
		_built_settlement_2d.erase(v_key)

	if _built_settlement_3d.has(v_key):
		var s3: Node3D = _built_settlement_3d[v_key]
		if is_instance_valid(s3): s3.queue_free()
		_built_settlement_3d.erase(v_key)

	# Spawn city visuals
	var v: SettlementSpaceModel = _v_by_key.get(v_key) as SettlementSpaceModel
	if v != null:
		_spawn_built_city_2d(v)
		_spawn_built_city_3d(v)

	# If you tint space legality, keep it unchanged—upgrade doesn’t alter spacing rules.

func add_port(pos_key: Vector2i, port_type: String, rate: int) -> void:
	# Stub: records a port and creates a simple visual (no real positioning yet).
	ports.append({ "pos": pos_key, "type": port_type, "rate": rate })
	if debug_verbose: print("[World] add_port pos=", pos_key, " type=", port_type, " rate=", rate)
	if _world2d != null:
		var p2 := Port2D.new()
		# If you later compute a 2D position from pos_key, set p2.position here.
		_world2d.add_child(p2)
		p2.setup(port_type, rate)


func get_best_bank_rate_for(player_id: int, resource: String) -> int:
	# Stubbed logic: return the best (lowest) rate among defined ports
	# if type matches resource or is ANY. Does NOT check adjacency yet.
	var best := 4
	for p in ports:
		if p["type"] == resource or p["type"] == "ANY":
			best = min(best, int(p["rate"]))
	if debug_verbose: print("[World] best bank rate for P", player_id, " res=", resource, " -> ", best)
	return best


func place_settlement(player_id:int, v_key: Vector2i, ignore_connectivity: bool = false) -> bool:
	if not can_place_settlement(player_id, v_key, ignore_connectivity):
		return false
	var v: SettlementSpaceModel = _v_by_key[v_key] as SettlementSpaceModel
	v.occupied_by = player_id
	emit_signal("settlement_added", v)
	_recompute_legality()
	_spawn_built_settlement_2d(v)
	_spawn_built_settlement_3d(v)
	_update_space_legality_visuals_around_vertex(v_key)
	return true

func place_road(player_id:int, e_key: Vector2i, ignore_connectivity: bool = false) -> bool:
	if not can_place_road(player_id, e_key, ignore_connectivity):
		return false
	var e: RoadSpaceModel = _e_by_key[e_key] as RoadSpaceModel
	e.occupied_by = player_id
	emit_signal("road_added", e)
	_recompute_legality()
	_spawn_built_road_2d(e)
	# optional: update nearby settlement-space legality visuals
	return true


func _update_space_legality_visuals_around_vertex(v_key: Vector2i) -> void:
	var center: SettlementSpaceModel = _v_by_key.get(v_key) as SettlementSpaceModel
	if center != null and _v2d_by_key.has(v_key):
		(_v2d_by_key[v_key] as SettlementSpace2D).apply_state(center.is_build_legal)
	for nb: Vector2i in _neighbors_of_vertex(v_key):
		var vv: SettlementSpaceModel = _v_by_key.get(nb) as SettlementSpaceModel
		if vv != null and _v2d_by_key.has(nb):
			(_v2d_by_key[nb] as SettlementSpace2D).apply_state(vv.is_build_legal)


func attach_views(world2d: Node2D, world3d: Node3D) -> void:
	_world2d = world2d
	_world3d = world3d
	# hexes
	for h: HexModel in hexes:
		_spawn_hex_views(h)
	# spaces
	for v: SettlementSpaceModel in settlement_spaces:
		_spawn_settlement_space_views(v)
	for e: RoadSpaceModel in road_spaces:
		_spawn_road_space_views(e)
	# built pieces (if any placed during setup)
	for v2: SettlementSpaceModel in settlement_spaces:
		if v2.occupied_by != -1:
			_spawn_built_settlement_2d(v2)
			_spawn_built_settlement_3d(v2)
	for e2: RoadSpaceModel in road_spaces:
		if e2.occupied_by != -1:
			_spawn_built_road_2d(e2)
	# signals for future placements (if you emit them)
	settlement_added.connect(func(model): _spawn_built_settlement_2d(model))
	road_added.connect(func(model): _spawn_built_road_2d(model))


func _spawn_built_settlement_2d(v: SettlementSpaceModel) -> void:
	if _world2d == null: return
	if v.occupied_by == -1: return
	if _built_settlement_2d.has(v.key): return
	var s := Settlement2D.new()
	s.position = v.position
	_world2d.add_child(s)
	_built_settlement_2d[v.key] = s
	s.apply_owner(_player_color(v.occupied_by))

func _spawn_built_road_2d(e: RoadSpaceModel) -> void:
	if _world2d == null: return
	if e.occupied_by == -1: return
	if _built_road_2d.has(e.key): return
	var r := Road2D.new()
	r.position = e.position
	var a_model: SettlementSpaceModel = _v_by_key.get(e.a) as SettlementSpaceModel
	var b_model: SettlementSpaceModel = _v_by_key.get(e.b) as SettlementSpaceModel
	if a_model == null or b_model == null:
		return
	r.a_local = a_model.position - e.position
	r.b_local = b_model.position - e.position
	_world2d.add_child(r)
	_built_road_2d[e.key] = r
	r.apply_owner(_player_color(e.occupied_by))


func _spawn_settlement_space_views(v: SettlementSpaceModel) -> void:
	if _world2d:
		var n := SettlementSpace2D.new()
		n.position = v.position
		_world2d.add_child(n)
		_v2d_by_key[v.key] = n
		n.apply_state(v.is_build_legal)

func _spawn_road_space_views(e: RoadSpaceModel) -> void:
	if _world2d:
		var n := RoadSpace2D.new()
		n.position = e.position
		var a_model: SettlementSpaceModel = _v_by_key.get(e.a) as SettlementSpaceModel
		var b_model: SettlementSpaceModel = _v_by_key.get(e.b) as SettlementSpaceModel
		if a_model == null or b_model == null:
			return
		n.a_local = a_model.position - e.position
		n.b_local = b_model.position - e.position
		_world2d.add_child(n)
		_e2d_by_key[e.key] = n

# -------- BUILDERS --------
func build_hex_ring(radius: int, resource_ratios: Dictionary) -> void:
	hexes.clear()
	settlement_spaces.clear()
	road_spaces.clear()
	_v_by_key.clear()
	_e_by_key.clear()

	# 1) axial coords
	var coords: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		var r1: int = max(-radius, -q - radius)
		var r2: int = min(radius, -q + radius)
		for r in range(r1, r2 + 1):
			coords.append(Vector2i(q, r))

	# 2) weighted resources (naive)
	var bag: Array[String] = _make_weighted_bag(resource_ratios, coords.size())
	var i: int = 0
	for c: Vector2i in coords:
		var m := HexModel.new()
		m.q = c.x
		m.r = c.y
		m.resource = bag[i % bag.size()]
		hexes.append(m)
		emit_signal("hex_added", m)
		i += 1
	# Assign roll numbers (skip deserts) so expected yields and production work
	_assign_chits_for_radius2()
	# 3) derive SettlementSpaces (corners) and RoadSpaces (edges)
	_build_spaces_from_hexes()
	_recompute_legality()          # ensure is_build_legal is set before Economy runs
	for v: SettlementSpaceModel in settlement_spaces:
		_update_settlement_view(v)
	for e: RoadSpaceModel in road_spaces:
		_update_road_view(e)


func _build_spaces_from_hexes() -> void:
	for h: HexModel in hexes:
		var center: Vector2 = _axial_to_pixel(Vector2(h.q, h.r), hex_size)
		var corners: Array[Vector2] = _hex_points(hex_size) # relative positions
		var corner_keys: Array[Vector2i] = []

		# --- corners ---
		for p_rel: Vector2 in corners:
			var p: Vector2 = center + p_rel
			var k: Vector2i = _key(p)
			var v: SettlementSpaceModel = null
			if _v_by_key.has(k):
				v = _v_by_key[k] as SettlementSpaceModel
			if v == null:
				v = SettlementSpaceModel.new()
				v.key = k
				v.position = p
				_v_by_key[k] = v
				settlement_spaces.append(v)
				emit_signal("settlement_space_added", v)
			v.adjacent_hexes.append(Vector2i(h.q, h.r))
			corner_keys.append(k)
			_recompute_legality()
			for vv: SettlementSpaceModel in settlement_spaces:
				_update_settlement_view(vv)
			for e: RoadSpaceModel in road_spaces:
				_update_road_view(e)


		# --- edges between consecutive corners ---
		for idx in range(6):
			var j: int = (idx + 1) % 6
			var p1: Vector2 = center + corners[idx]
			var p2: Vector2 = center + corners[j]
			var mid: Vector2 = (p1 + p2) * 0.5
			var ek: Vector2i = _key(mid)

			var e: RoadSpaceModel = null
			if _e_by_key.has(ek):
				e = _e_by_key[ek] as RoadSpaceModel
			if e == null:
				e = RoadSpaceModel.new()
				e.key = ek
				e.position = mid
				e.a = corner_keys[idx]
				e.b = corner_keys[j]
				_e_by_key[ek] = e
				road_spaces.append(e)
				emit_signal("road_space_added", e)
			e.adjacent_hexes.append(Vector2i(h.q, h.r))

# -------- VIEW SPLICING --------
func _spawn_hex_views(h: HexModel) -> void:
	if _world2d:
		var h2 := Hex2D.new()
		h2.label = "%s\n(%d,%d)" % [h.resource, h.q, h.r]
		h2.size = hex_size
		h2.color = _res_color(h.resource)
		h2.position = _axial_to_pixel(Vector2(h.q, h.r), hex_size)
		_world2d.add_child(h2)
	if _world3d:
		var res_str: String = _res_to_string(h.resource)
		var h3: Node3D = HexFactory.instantiate_for(res_str, h.q, h.r, hex_size, hex_height_3d)

		var p2: Vector2 = _axial_to_pixel(Vector2(h.q, h.r), hex_size)
		h3.position = Vector3(p2.x, ground_y, p2.y)
		_world3d.add_child(h3)
		
# -------- helpers ----------
func _axial_to_pixel(ax: Vector2, size: float) -> Vector2:
	var x := size * (sqrt(3.0) * ax.x + sqrt(3.0) / 2.0 * ax.y)
	var y := size * (3.0 / 2.0 * ax.y)
	return Vector2(x, y)

func _hex_points(size: float) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for i in range(6):
		var a := PI / 6.0 + i * PI / 3.0
		pts.append(Vector2(cos(a), sin(a)) * size)
	return pts

func _key(p: Vector2) -> Vector2i:
	return Vector2i(roundi(p.x * KEY_SCALE), roundi(p.y * KEY_SCALE))

func _make_weighted_bag(ratios: Dictionary, count: int) -> Array[String]:
	var order: Array[String] = ["WOOD", "BRICK", "ORE", "WHEAT", "SHEEP", "DESERT"]
	var arr: Array[String] = []
	for k in order:
		var portion := int(round(float(ratios.get(k, 0.0)) * float(count)))
		for _i in portion:
			arr.append(k)
	if arr.is_empty():
		arr = ["DESERT"]
	arr.shuffle()
	return arr

func _res_color(r: String) -> Color:
	match r:
		"WOOD":  return Color(0.18, 0.55, 0.24)
		"BRICK": return Color(0.7, 0.25, 0.2)
		"ORE":   return Color(0.35, 0.35, 0.45)
		"WHEAT": return Color(0.95, 0.85, 0.35)
		"SHEEP": return Color(0.80, 0.95, 0.80)
		"DESERT":return Color(0.75, 0.65, 0.45)
		_:       return Color(0.6, 0.6, 0.6)

# NEW: public API for placements (rules checked here)
func can_place_settlement(player_id:int, v_key: Vector2i, ignore_connectivity: bool = false) -> bool:
	var v: SettlementSpaceModel = _v_by_key.get(v_key) as SettlementSpaceModel
	if v == null or v.occupied_by != -1:
		return false
	# distance rule: no neighboring settlement
	for nb in _neighbors_of_vertex(v_key):
		var vv: SettlementSpaceModel = _v_by_key.get(nb) as SettlementSpaceModel
		if vv != null and vv.occupied_by != -1:
			return false
	# connectivity (skip during initial setup)
	if ignore_connectivity:
		return true
	# require at least one adjacent road or owned vertex
	for e_key: Vector2i in _edges_touching_vertex(v_key):
		var e: RoadSpaceModel = _e_by_key.get(e_key) as RoadSpaceModel
		if e != null and e.occupied_by == player_id:
			return true
	return false

# NEW: recompute legality flags after any placement
func _recompute_legality() -> void:
	# Settlements: legal if empty and no adjacent occupied settlements
	for v: SettlementSpaceModel in settlement_spaces:
		var ok := v.occupied_by == -1
		if ok:
			for nb in _neighbors_of_vertex(v.key):
				var vv: SettlementSpaceModel = _v_by_key.get(nb) as SettlementSpaceModel
				if vv != null and vv.occupied_by != -1:
					ok = false; break
		v.is_build_legal = ok

	# Roads: legal if empty and connects to any owned settlement/road of any player (real rule uses active player)
	for e: RoadSpaceModel in road_spaces:
		var ok2 := e.occupied_by == -1
		e.is_build_legal = ok2

# Graph helpers
func _neighbors_of_vertex(v_key: Vector2i) -> Array[Vector2i]:
	# vertices adjacent via one edge
	var out: Array[Vector2i] = []
	for e: RoadSpaceModel in road_spaces:
		if e.a == v_key:
			out.append(e.b)
		elif e.b == v_key:
			out.append(e.a)
	return out

func _edges_touching_edge(e_key: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var e: RoadSpaceModel = _e_by_key.get(e_key) as RoadSpaceModel
	if e == null:
		return out
	for nb_key: Vector2i in _edges_touching_vertex(e.a):
		if nb_key != e_key:
			out.append(nb_key)
	for nb_key2: Vector2i in _edges_touching_vertex(e.b):
		if nb_key2 != e_key:
			out.append(nb_key2)
	return out

func _assign_chits_for_radius2() -> void:
	var nums: Array[int] = [5,2,6,3,8,10,9,12,11,4,8,10,9,4,5,6,3,11,5,2,6,3,8,10,9,12,11,4,8,10,9,4,5,6,3,11,5,2,6,3,8,10,9,12,11,4,8,10,9,4,5,6,3,11,5,2,6,3,8,10,9,12,11,4,8,10,9,4,5,6,3,11]
	nums.shuffle()
	var idx := 0
	for h: HexModel in hexes:
		if h.resource == "DESERT":
			h.roll_number = 0
		else:
			h.roll_number = nums[idx]
			idx += 1

func _player_color(id:int) -> Color:
	var pal: Array[Color] = [
		Color(0.9,0.2,0.2),   # red
		Color(0.2,0.6,1.0),   # blue
		Color(0.2,0.8,0.2),   # green
		Color(0.95,0.7,0.2),  # orange
		Color(0.7,0.4,0.9),   # purple
		Color(0.9,0.9,0.2)    # yellow
	]
	return pal[id % pal.size()]

func _update_settlement_view(v: SettlementSpaceModel) -> void:
	var node: SettlementSpace2D = _v2d_by_key.get(v.key) as SettlementSpace2D
	if node != null:
		# update legality tint only
		node.apply_state(v.is_build_legal)

	# If this space is occupied, update (or create) a Settlement2D
	if v.occupied_by != -1:
		if not _built_settlement_2d.has(v.key):
			_spawn_built_settlement_2d(v)
		else:
			var s: Settlement2D = _built_settlement_2d[v.key] as Settlement2D
			s.apply_owner(_player_color(v.occupied_by))

func _update_road_view(e: RoadSpaceModel) -> void:
	var node: RoadSpace2D = _e2d_by_key.get(e.key) as RoadSpace2D
	if node != null:
		node.apply_state(e.occupied_by, e.is_build_legal, _player_color(e.occupied_by))

## Return all SettlementSpaceModel that touch a given hex (axial coords)
func get_vertices_touching_hex(ax: Vector2i) -> Array[SettlementSpaceModel]:
	var out: Array[SettlementSpaceModel] = []
	for v: SettlementSpaceModel in settlement_spaces:
		# you populate v.adjacent_hexes in _build_spaces_from_hexes()
		for h_ax: Vector2i in v.adjacent_hexes:
			if h_ax == ax:
				out.append(v)
				break
	return out

## Return all RoadSpaceModel (edges) that touch a given hex (axial coords)
func get_edges_touching_hex(ax: Vector2i) -> Array[RoadSpaceModel]:
	var out: Array[RoadSpaceModel] = []
	for e: RoadSpaceModel in road_spaces:
		for h_ax: Vector2i in e.adjacent_hexes:
			if h_ax == ax:
				out.append(e)
				break
	return out

## If you don’t already have these, add them too (typed versions)
func _edges_touching_vertex(v_key: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for e: RoadSpaceModel in road_spaces:
		if e.a == v_key or e.b == v_key:
			out.append(e.key)
	return out

func _hex_by_axial(ax: Vector2i) -> HexModel:
	for h: HexModel in hexes:
		if h.q == ax.x and h.r == ax.y:
			return h
	return null
func move_robber(ax: Vector2i) -> void:
	if debug_verbose: print("[World] move_robber ", _robber_pos, " -> ", ax)
	_robber_pos = ax
	if _world2d != null:
		if _robber_node == null:
			_robber_node = Robber2D.new()
			_world2d.add_child(_robber_node)
		# Position at the hex center (use your axial->pixel helper)
		var p2: Vector2 = _axial_to_pixel(Vector2(ax.x, ax.y), hex_size)
		_robber_node.position = p2
		if debug_verbose: print("  -> Robber2D moved to ", p2)


func get_players_adjacent_to_robber() -> Array[int]:
	# Returns unique player_ids that have a settlement/city touching the robber hex.
	var out: Array[int] = []
	var seen := {}
	var verts := get_vertices_touching_hex(_robber_pos)
	for v: SettlementSpaceModel in verts:
		if v.occupied_by != -1 and not seen.has(v.occupied_by):
			seen[v.occupied_by] = true
			out.append(v.occupied_by)
	if debug_verbose: print("[World] players_adjacent_to_robber at ", _robber_pos, " -> ", out)
	return out

func replace_settlement_with_city(player_id: int, v_key: Vector2i) -> bool:
	# Ensure legality
	if not can_place_city(player_id, v_key):
		return false

	# Mark upgrade in state
	_cities_at[v_key] = player_id

	# Remove old settlement visuals
	if _built_settlement_2d.has(v_key):
		var s2: Node2D = _built_settlement_2d[v_key]
		if is_instance_valid(s2): s2.queue_free()
		_built_settlement_2d.erase(v_key)

	if _built_settlement_3d.has(v_key):
		var s3: Node3D = _built_settlement_3d[v_key]
		if is_instance_valid(s3): s3.queue_free()
		_built_settlement_3d.erase(v_key)

	# Spawn city visuals at same vertex
	var v: SettlementSpaceModel = _v_by_key.get(v_key) as SettlementSpaceModel
	if v != null:
		_spawn_built_city_2d(v)
		_spawn_built_city_3d(v)

	if debug_verbose:
		print("[World] Replaced settlement with city at %s for pid=%d" % [str(v_key), player_id])
	return true

func _res_to_string(res) -> String:
	# In this project, resources are already strings (set in build_hex_ring()).
	if typeof(res) == TYPE_STRING:
		return (res as String).to_upper()
	return "DESERT"

func remove_building_by_node(bldg3d: Node3D, cause: String = "captured") -> void:
	if bldg3d == null:
		if debug_verbose:
			print("[World] remove_building_by_node: null node (cause=", cause, ")")
		return

	# 1) Get Variant (can be Vector2i or null). Use "=" (dynamic), not ":=" (typed inference).
	var key_v = _key_for_building_3d(bldg3d)
	if key_v == null:
		if debug_verbose:
			print("[World][WARN] remove_building_by_node: could not resolve key for ", bldg3d.name,
				" (cause=", cause, ") — removing 3D only")
		if is_instance_valid(bldg3d):
			bldg3d.queue_free()
		return

	# 2) Safe cast to the typed key now that we know it's not null.
	var key: Vector2i = key_v
	_remove_building_at_key(key, cause)


	_remove_building_at_key(key as Vector2i, cause)

func _key_for_building_3d(bldg3d: Node3D) -> Variant:
	# Match pointer equality against our fast maps
	for k in _built_settlement_3d.keys():
		if _built_settlement_3d[k] == bldg3d:
			return k
	for k in _built_city_3d.keys():
		if _built_city_3d[k] == bldg3d:
			return k
	return null

func _remove_building_at_key(key: Vector2i, cause: String = "") -> void:
	if debug_verbose:
		print("[World] remove-building key=", key, " cause=", cause)

	# --- 3D views ---
	if _built_settlement_3d.has(key):
		var s3 = _built_settlement_3d[key]
		if debug_verbose: print("[World] 3D settlement remove @", key, " node=", s3)
		if is_instance_valid(s3): s3.queue_free()
		_built_settlement_3d.erase(key)

	if _built_city_3d.has(key):
		var c3 = _built_city_3d[key]
		if debug_verbose: print("[World] 3D city remove @", key, " node=", c3)
		if is_instance_valid(c3): c3.queue_free()
		_built_city_3d.erase(key)

	# --- 2D views ---
	if _built_settlement_2d.has(key):
		var s2 = _built_settlement_2d[key]
		if debug_verbose: print("[World] 2D settlement remove @", key, " node=", s2)
		if is_instance_valid(s2): s2.queue_free()
		_built_settlement_2d.erase(key)

	if _built_city_2d.has(key):
		var c2 = _built_city_2d[key]
		if debug_verbose: print("[World] 2D city remove @", key, " node=", c2)
		if is_instance_valid(c2): c2.queue_free()
		_built_city_2d.erase(key)

	# --- Model / occupancy ---
	if _v_by_key.has(key):
		var v = _v_by_key[key]
		if debug_verbose: print("[World] model clear occupy @", key)
		# SettlementSpaceModel usually exposes occupied_by
		if "occupied_by" in v:
			v.occupied_by = -1

	# Clear any city flags we track
	if _cities_at.has(key):
		_cities_at.erase(key)

	# --- 2D space node mirror ---
	if _v2d_by_key.has(key):
		var space2d = _v2d_by_key[key]
		if space2d and space2d.has_method("clear_occupation"):
			if debug_verbose: print("[World] 2D space clear @", key)
			space2d.clear_occupation()

# Returns all vertex keys where a settlement can be placed during SETUP:
# - must be unoccupied
# - must satisfy the distance rule (no adjacent settlements)
# - ignores road connectivity and resource costs
func list_setup_legal_vertices() -> Array:
	var result: Array = []

	# Collect all known vertex keys from the internal map
	var keys: Array = []
	if typeof(_v2d_by_key) == TYPE_DICTIONARY:
		keys = (_v2d_by_key as Dictionary).keys()
	else:
		# If your project exposes a different source, adapt here
		return result

	# Build a quick lookup of which vertices are currently occupied
	var occupied: Dictionary = {}   # Vector2i -> true
	for k in keys:
		var kv: Vector2i = k
		if _is_vertex_occupied_setup(kv):
			occupied[kv] = true

	# Keep any vertex that is free AND has no adjacent occupied vertex
	for k in keys:
		var kv: Vector2i = k
		if occupied.has(kv):
			continue
		var neighbors: Array = _adjacent_vertices_setup(kv)
		var blocked: bool = false
		for n in neighbors:
			var nv: Vector2i = n
			if occupied.has(nv):
				blocked = true
				break
		if not blocked:
			result.append(kv)

	return result


# --- helpers used by list_setup_legal_vertices() -----------------------------

# Best-effort check whether a vertex is currently occupied by ANY settlement.
# Adapts to common field/method names on your SettlementSpace2D.
func _is_vertex_occupied_setup(key: Vector2i) -> bool:
	if typeof(_v2d_by_key) != TYPE_DICTIONARY:
		return false
	var sp: Variant = (_v2d_by_key as Dictionary).get(key)
	if sp == null:
		return false

	# Preferred explicit method
	if sp is Object and (sp as Object).has_method("has_settlement"):
		return bool((sp as Object).call("has_settlement"))

	# Common field styles: occupied_by (>=0), is_occupied, has_settlement, built
	var occ = null
	occ = (sp as Object).get("occupied_by") if sp is Object else null
	if occ != null:
		return int(occ) >= 0

	occ = (sp as Object).get("is_occupied") if sp is Object else null
	if occ != null:
		return bool(occ)

	occ = (sp as Object).get("has_settlement") if sp is Object else null
	if occ != null:
		return bool(occ)

	occ = (sp as Object).get("built") if sp is Object else null
	if occ != null:
		return bool(occ)

	return false


# Returns neighboring vertex keys (one road away) for a given vertex key.
# Adapts to common neighbor accessors present on SettlementSpace2D.
func _adjacent_vertices_setup(key: Vector2i) -> Array:
	var out: Array = []
	if typeof(_v2d_by_key) != TYPE_DICTIONARY:
		return out

	var sp: Variant = (_v2d_by_key as Dictionary).get(key)
	if sp == null:
		return out

	# If the world already exposes adjacency, prefer that
	if (self as Object).has_method("adjacent_vertices"):
		var v: Variant = (self as Object).call("adjacent_vertices", key)
		if typeof(v) == TYPE_ARRAY:
			return v

	# Otherwise try common fields/methods on the space object
	if sp is Object and (sp as Object).has_method("neighbor_keys"):
		var v2: Variant = (sp as Object).call("neighbor_keys")
		if typeof(v2) == TYPE_ARRAY:
			return v2

	if sp is Object:
		var nv = (sp as Object).get("neighbor_keys")
		if nv != null and typeof(nv) == TYPE_ARRAY:
			return nv
		var n2 = (sp as Object).get("neighbors")
		if n2 != null and typeof(n2) == TYPE_ARRAY:
			return n2

	return out

func debug_explain_can_place_setup(pid: int, v_key: Vector2i) -> void:
	print("[World][SETUP][DBG] explain setup placement pid=", pid, " v=", v_key)

	# 0) graph snapshot
	var v_count: int = -1
	if typeof(_v_by_key) == TYPE_DICTIONARY:
		var vdict: Dictionary = _v_by_key
		v_count = vdict.size()

	var e_count: int = -1
	if typeof(_e_by_key) == TYPE_DICTIONARY:
		var edict: Dictionary = _e_by_key
		e_count = edict.size()

	print("   graph: |V|=", v_count, " |E|=", e_count)

	# 1) occupancy (use dynamic call, else fallback)
	var self_occ: bool = false
	if (self as Object).has_method("is_vertex_occupied"):
		self_occ = bool((self as Object).call("is_vertex_occupied", v_key))
	else:
		self_occ = _is_vertex_occupied_setup(v_key)
	print("   occupied_self=", self_occ)

	# 2) neighbor distance rule (prefer world API, else derive from _e_by_key)
	var neigh: Array[Vector2i] = []
	if (self as Object).has_method("adjacent_vertices"):
		var nv: Variant = (self as Object).call("adjacent_vertices", v_key)
		if typeof(nv) == TYPE_ARRAY:
			neigh = nv
	elif (self as Object).has_method("neighbor_vertex_keys"):
		var nv2: Variant = (self as Object).call("neighbor_vertex_keys", v_key)
		if typeof(nv2) == TYPE_ARRAY:
			neigh = nv2
	else:
		neigh = _neighbor_vertex_keys_fallback(v_key)  # defined below

	var neighbor_occ: bool = false
	for n in neigh:
		var n_occ: bool = false
		if (self as Object).has_method("is_vertex_occupied"):
			n_occ = bool((self as Object).call("is_vertex_occupied", n))
		else:
			n_occ = _is_vertex_occupied_setup(n)
		if n_occ:
			neighbor_occ = true
			break
	print("   neighbor_count=", neigh.size(), " any_neighbor_occupied=", neighbor_occ)

	# 3) road connectivity (often ignored during setup)
	if (self as Object).has_method("has_player_road_adjacent"):
		var road_adj: bool = bool((self as Object).call("has_player_road_adjacent", pid, v_key))
		print("   has_player_road_adjacent=", road_adj, " (ignored in setup)")
	else:
		print("   has_player_road_adjacent= <no API> (ignored in setup)")

	# 4) can_place APIs (read-only probe; detects common signatures)
	if (self as Object).has_method("can_place_settlement"):
		var argc: int = _method_argc("can_place_settlement")
		var ok_norm: bool = false
		if argc == 3:
			ok_norm = bool((self as Object).callv("can_place_settlement", [pid, v_key, false]))
		elif argc == 2:
			ok_norm = bool((self as Object).callv("can_place_settlement", [pid, v_key]))
		else:
			print("   can_place_settlement signature unexpected; argc=", argc)
		print("   can_place_settlement(...) -> ", ok_norm)
	else:
		print("   can_place_settlement= <no API>")

	if (self as Object).has_method("can_place_settlement_setup"):
		var ok_setup: bool = bool((self as Object).call("can_place_settlement_setup", pid, v_key))
		print("   can_place_settlement_setup(pid,v) -> ", ok_setup)
	else:
		print("   can_place_settlement_setup= <no API>")

	# 5) resource profile at this vertex
	if (self as Object).has_method("vertex_resource_profile"):
		var prof_v: Variant = (self as Object).call("vertex_resource_profile", v_key)
		print("   vertex_resource_profile=", prof_v)
	elif (self as Object).has_method("vertex_adjacent_resources"):
		var arr: Variant = (self as Object).call("vertex_adjacent_resources", v_key)
		if typeof(arr) == TYPE_ARRAY:
			# Build a tiny histogram just for display
			var prof2: Dictionary = {}
			for r in (arr as Array):
				prof2[r] = float(prof2.get(r, 0.0)) + 1.0
			print("   vertex_adjacent_resources fallback=", prof2)
		else:
			print("   vertex_adjacent_resources returned non-array")
	else:
		print("   vertex_resource_profile= <no API>")

# Count args of a method on this object (0 if not found)
func _method_argc(name: String) -> int:
	var mlist: Array = (self as Object).get_method_list()
	for m in mlist:
		if typeof(m) == TYPE_DICTIONARY and String(m.get("name","")) == name:
			var args: Variant = m.get("args")
			return (args.size() if typeof(args) == TYPE_ARRAY else 0)
	return 0

# Fallback neighbor finder using _e_by_key: looks for edges that touch v_key
func _neighbor_vertex_keys_fallback(v_key: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if typeof(_e_by_key) != TYPE_DICTIONARY:
		return out
	var edict: Dictionary = _e_by_key
	for ekey in edict.keys():
		var em: Variant = edict[ekey]
		if em == null: continue
		var a_any: Variant = (em as Object).get("a") if em is Object else null
		var b_any: Variant = (em as Object).get("b") if em is Object else null
		if typeof(a_any) == TYPE_VECTOR2I and typeof(b_any) == TYPE_VECTOR2I:
			var a: Vector2i = a_any
			var b: Vector2i = b_any
			if a == v_key:
				out.append(b)
			elif b == v_key:
				out.append(a)
		elif (em as Object).has_method("get_a") and (em as Object).has_method("get_b"):
			var a2: Variant = (em as Object).call("get_a")
			var b2: Variant = (em as Object).call("get_b")
			if typeof(a2) == TYPE_VECTOR2I and typeof(b2) == TYPE_VECTOR2I:
				var av: Vector2i = a2
				var bv: Vector2i = b2
				if av == v_key:
					out.append(bv)
				elif bv == v_key:
					out.append(av)
	return out

# --- Public wrappers to help AI during SETUP ---

func edges_touching_vertex(v_key: Vector2i) -> Array[Vector2i]:
	# Non-underscored wrapper so external callers don't need to know internals.
	return _edges_touching_vertex(v_key)

func list_setup_legal_road_edges_from_vertex(pid: int, v_key: Vector2i) -> Array[Vector2i]:
	# Edges touching v_key that are legal to place *during setup*.
	# Ignore connectivity; the AI already restricts to edges off the fresh settlement.
	var out: Array[Vector2i] = []
	var edges: Array = _edges_touching_vertex(v_key)
	for e in edges:
		var ee: Vector2i = e
		if can_place_road(pid, ee, true): # <— ignore_connectivity = true
			out.append(ee)
	return out

# Back-compat alias some agents might look for
func list_setup_legal_edges_from_vertex(pid: int, v_key: Vector2i) -> Array[Vector2i]:
	return list_setup_legal_road_edges_from_vertex(pid, v_key)

func can_place_road_setup(pid: int, e_key: Vector2i) -> bool:
	return can_place_road(pid, e_key, true)

func place_road_setup(pid: int, e_key: Vector2i) -> bool:
	return place_road(pid, e_key, true)

# Common synonyms some agents expect:
func adjacent_road_edges_from_vertex(v_key: Vector2i) -> Array[Vector2i]:
	return edges_touching_vertex(v_key)

func get_adjacent_road_edges(v_key: Vector2i) -> Array[Vector2i]:
	return edges_touching_vertex(v_key)

func list_buildable_road_edges_from_vertex(pid: int, v_key: Vector2i) -> Array[Vector2i]:
	# Normal (non-setup) legality from a specific vertex.
	var out: Array[Vector2i] = []
	var edges: Array = _edges_touching_vertex(v_key)
	for e in edges:
		var ee: Vector2i = e
		if can_place_road(pid, ee, false):
			out.append(ee)
	return out

func list_buildable_road_targets_from_vertex(pid: int, v_key: Vector2i) -> Array[Vector2i]:
	return list_buildable_road_edges_from_vertex(pid, v_key)

func edge_key_from_vertices(a: Vector2i, b: Vector2i) -> Vector2i:
	# Convenience: find the edge key that connects a<->b if it exists.
	for e in road_spaces:
		if (e.a == a and e.b == b) or (e.a == b and e.b == a):
			return e.key
	return Vector2i(0, 0) # invalid sentinel; caller should check can_place_road before using.

func has_road_view_2d(e_key: Vector2i) -> bool:
	return _built_road_2d.has(e_key)



# --- end setup helpers ---
