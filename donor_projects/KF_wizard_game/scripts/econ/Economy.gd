extends Node
class_name Economy

@export var debug_verbose: bool = true
@export var debug_very_verbose: bool = true

var __apportion_quotas: Array[float] = []

func _apportion_compare(a: int, b: int) -> bool:
	var fa: float = __apportion_quotas[a]
	var fb: float = __apportion_quotas[b]
	var ra: float = fa - floor(fa)
	var rb: float = fb - floor(fb)
	return ra > rb
## ---------- Signals (for HUD/logs) ----------
signal build_success(pid: int, kind: String, key: Vector2i)
signal build_failed(pid: int, kind: String, key: Vector2i, reason: String)
signal vp_changed(pid: int, vp: int)
signal inventory_changed(pid: int, inventory: Dictionary)
signal inventories_dumped(snapshot: Dictionary)  # optional, for one-shot dumps

signal trade_offered(pid: int, offer: Dictionary, request: Dictionary)
signal trade_completed(pid: int, partner_pid: int, offer: Dictionary, request: Dictionary)
signal trade_declined(pid: int, partner_pid: int)

# Compatibility / future
signal setup_placed(pid: int, v: Vector2i, e: Vector2i)
signal dice_rolled(total: int)
signal resources_distributed(roll: int)
signal phase_changed(phase: String)
signal winner(pid: int)
## ---------- Config ----------
@export var TurnTime: float = 0.1     # seconds per step for pacing (changed to 5 seconds)
@export var WIN_POINTS: int = 20       # with settlements only, first to 5 wins

## ---------- Costs (basic Catan) ----------
const COST_SETTLEMENT: Dictionary = {"WOOD": 1, "BRICK": 1, "WHEAT": 1, "SHEEP": 1}
const COST_CITY: Dictionary = {"ORE": 3, "WHEAT": 2}
const COST_ROAD: Dictionary       = {"WOOD": 1, "BRICK": 1}
const TRADE_RATE_HARBOR: int = 2  # Standard harbor trade rate
const TRADE_RATE_GENERIC: int = 4  # Default trade rate without harbor

## ---------- AI player ratios ------------
var ratioAISmart 	: int = 0
var ratioAISpiteful : int = 0
var ratioAIStupid 	: int = 1

## ---------- Types ----------
const EconomyPlayer    := preload("res://scripts/econ/EconomyPlayer.gd")
const AIEconomyPlayer  := preload("res://scripts/econ/AIEconomyPlayer.gd")
const SmartAIPlayer    := preload("res://scripts/econ/SmartAIPlayer.gd")
const SpitefulAIPlayer := preload("res://scripts/econ/SpitefulAIPlayer.gd")
const StupidAIPlayer   := preload("res://scripts/econ/StupidAIPlayer.gd")
const DevCardDeck      := preload("res://scripts/model/DevCardDeck.gd")
const DevCard          := preload("res://scripts/model/DevCard.gd")

var dev_deck: DevCardDeck

## ---------- Runtime State ----------
var world: Object                             # AbstractWorld
var players: Array[EconomyPlayer] = []
var current_player_index: int = 0
var is_running: bool = false
var is_setup_phase: bool = true  # Track if we're in setup phase

# pid -> inventories and VP
var inventories: Dictionary = {}       # { pid: {"WOOD":int,"BRICK":int,"WHEAT":int,"SHEEP":int,"ORE":int} }
var vp_by_pid: Dictionary = {}         # { pid: int }

var _rng := RandomNumberGenerator.new()

signal turn_started(pid: int)
signal turn_ended(pid: int)

var _awaiting_player_id: int = -1

# --- Economy.gd ---------------------------------------------------------------

func _distribute_resources_for_roll(roll: int) -> void:
	if debug_verbose:
		print("[Economy] distributing resources start (roll=", roll, ")")

	if world == null or not world.has_method("_hex_by_axial"):
		if debug_verbose:
			print("[Economy][WARN] world or _hex_by_axial missing; cannot distribute.")
		return

	# Ensure everyone has an inventory
	for p in players:
		_ensure_inventory(p.player_id)

	var paid_count := 0

	# Walk all settlement vertices and pay for adjacent hexes that match the roll
	if typeof(world.get("settlement_spaces")) == TYPE_ARRAY:
		for s in world.settlement_spaces:
			if s == null:
				continue

			var occ_pid: int = -1
			var v_key: Vector2i = Vector2i.ZERO
			var adj: Array = []

			if s is Dictionary:
				occ_pid = int(s.get("occupied_by", -1))
				v_key = s.get("key", Vector2i.ZERO)
				adj = s.get("adjacent_hexes", [])
			elif s is Object and s.has_method("get"):
				occ_pid = int(s.get("occupied_by"))
				v_key = s.get("key")
				adj = s.get("adjacent_hexes")
			else:
				continue

			if occ_pid < 0:
				continue  # empty vertex

			for h_ax in adj:
				if typeof(h_ax) != TYPE_VECTOR2I:
					continue
				var h = world._hex_by_axial(h_ax)
				if h == null:
					continue

				var res := ""
				var num := 0
				if h is Dictionary:
					res = str(h.get("resource", ""))
					num = int(h.get("roll_number", 0))
				elif h is Object and h.has_method("get"):
					res = str(h.get("resource"))
					num = int(h.get("roll_number"))

				if res == "" or res == "DESERT" or num != roll:
					continue

				var amount := 2 if _is_city_at_vertex(v_key) else 1
				_give_resource(occ_pid, res, amount)
				paid_count += 1

				if debug_verbose:
					print("[Economy][PAY] roll=", roll, " pid=", occ_pid, " +", amount, " ", res,
						" via hex ", h_ax, " @ vertex ", v_key)

	if debug_verbose:
		print("[Economy] distributing resources done; pays=", paid_count)
		_dbg_dump_all_inventories()


var rng := RandomNumberGenerator.new()


const RESOURCE_KEYS := ["WOOD","BRICK","WHEAT","SHEEP","ORE"]

func _is_city_at_vertex(v: Vector2i) -> bool:
	if world and world.has_method("is_city_vertex"):
		return bool(world.is_city_vertex(v))

	# Fallback: look for a vertex model with flags/level
	if world and typeof(world.get("_v_by_key")) == TYPE_DICTIONARY:
		var vm = world._v_by_key.get(v) if world._v_by_key.has(v) else null
		if vm != null:
			if vm is Dictionary and vm.has("is_city"):
				return bool(vm["is_city"])
			if vm is Object:
				if vm.has_method("get") and vm.get("is_city") != null:
					return bool(vm.get("is_city"))
				if vm.has_method("get") and vm.get("level") != null:
					return int(vm.get("level")) >= 2
	return false


func _compute_ai_class_list_exact(total_players: int) -> Array:
	var weights = [
		{"key":"smart",    "w": max(0, ratioAISmart),    "klass": SmartAIPlayer},
		{"key":"spiteful", "w": max(0, ratioAISpiteful), "klass": SpitefulAIPlayer},
		{"key":"stupid",   "w": max(0, ratioAIStupid),   "klass": StupidAIPlayer},
	]

	var sum_w := 0
	for e in weights:
		sum_w += e.w

	# Fallback: all zero -> use basic AI
	if sum_w == 0:
		return _filled_array(AIEconomyPlayer, total_players)

	# Hamilton (largest remainder) apportionment
	var quotas: Array[float] = []
	for e in weights:
		quotas.append(float(e.w) * float(total_players) / float(sum_w))

	var counts: Array[int] = []
	var base_sum := 0
	for q in quotas:
		var c := int(floor(q))
		counts.append(c)
		base_sum += c

	var remaining := total_players - base_sum
	if remaining > 0:
		# indices sorted by descending remainder
		# ✅ Godot 4 fix: assign the lambda to a variable, then pass it to sort_custom
		# indices sorted by descending remainder
		var idxs: Array[int] = []
		for i in range(quotas.size()):
			idxs.append(i)

		__apportion_quotas = quotas.duplicate()
		idxs.sort_custom(Callable(self, "_apportion_compare"))
		############

		for j in range(remaining):
			counts[idxs[j]] += 1

	# Build the exact class list, then shuffle for variety
	var classes: Array = []
	for i in range(weights.size()):
		for _k in range(counts[i]):
			classes.append(weights[i].klass)
	_rng.shuffle(classes)
	return classes




func _ensure_inventory(pid: int) -> void:
	if not inventories.has(pid):
		var inv := {}
		for r in RESOURCE_KEYS:
			inv[r] = 0
		inventories[pid] = inv

func _grant(pid: int, res: String, amount: int) -> void:
	_ensure_inventory(pid)
	inventories[pid][res] = int(inventories[pid].get(res, 0)) + amount
	if debug_verbose:
		print("[Economy][DIST] +", amount, " ", res, " -> P", pid, " now=", inventories[pid])


func _ready() -> void:
	rng.randomize()

func _give_resource(pid: int, res: String, qty: int) -> void:
	if not inventories.has(pid):
		inventories[pid] = {}
	if not inventories[pid].has(res):
		inventories[pid][res] = 0
	inventories[pid][res] = int(inventories[pid][res]) + int(qty)

func _inv_to_string(pid: int) -> String:
	if not inventories.has(pid):
		return "{}"
	var parts: Array[String] = []
	for k in inventories[pid].keys():
		parts.append("%s:%d" % [str(k), int(inventories[pid][k])])
	return "{ " + ", ".join(parts) + " }"

func _dbg_dump_all_inventories() -> void:
	print("[Economy][INV] -------- inventories --------")
	for pid in inventories.keys():
		print("[Economy][INV] pid=", pid, " -> ", _inv_to_string(pid))

## ---------- Public lifecycle ----------
func start(world_ref: Object, num_players_in: int = 4) -> void:
	world = world_ref
	players.clear()
	inventories.clear()
	vp_by_pid.clear()
	is_setup_phase = true

	var count: int = max(1, num_players_in)
	for pid in range(count):
		var ai: EconomyPlayer = EconomyPlayer.new(pid, "AI %d" % pid)  # or your AI subclasses
		players.append(ai)
		inventories[pid] = {"WOOD":0,"BRICK":0,"WHEAT":0,"SHEEP":0,"ORE":0}
		vp_by_pid[pid] = 0
		ai.bind(self, world)
		# Economy -> Player
		turn_started.connect(ai._on_economy_turn_started)
		# Player  -> Economy
		ai.turn_finished.connect(_on_player_turn_finished)

	# --- Setup phase ---
	phase_changed.emit("setup")
	_run_setup() # don't await if it doesn't yield

	# --- Begin main loop ---
	is_setup_phase = false
	phase_changed.emit("main")
	current_player_index = 0
	is_running = true
	if debug_verbose: print("[Economy] going to start main loop")
	call_deferred("_kickoff_loop")  # keep coroutine alive independently

func _kickoff_loop() -> void:
	await _main_loop()


## ---------- Setup (snake order) ----------
func _run_setup() -> void:
	if debug_verbose: print("[Economy] running setup")
	# Round 1: 0..n-1 - no timer delays in setup
	for i in range(players.size()):
		var p: EconomyPlayer = players[i]
		p.request_setup_action()
		# No timer delay in setup phase
		
	# Round 2: n-1..0 - no timer delays in setup
	for j in range(players.size() - 1, -1, -1):
		var p2: EconomyPlayer = players[j]
		p2.request_setup_action()
		# No timer delay in setup phase
	# creating development deck
	if debug_verbose: print("[Economy] finished running setup")

#func _setup_turn(p: AIEconomyPlayer) -> void:
	## Settlement (ignore connectivity in setup)
	#var v_key: Vector2i = p.choose_settlement_vertex(world)
	#if v_key != Vector2i.ZERO and world.can_place_settlement(p.player_id, v_key, true):
		#world.place_settlement(p.player_id, v_key, true)
		## VP for settlement placed during setup
		#var new_vp: int = int(vp_by_pid.get(p.player_id, 0)) + 1
		#vp_by_pid[p.player_id] = new_vp
		#vp_changed.emit(p.player_id, new_vp)
#
		## Road touching that settlement (still setup leniency)
		#var e_key: Vector2i = p.choose_road_from_vertex(world, v_key)
		#if e_key != Vector2i.ZERO and world.can_place_road(p.player_id, e_key, true):
			#world.place_road(p.player_id, e_key, true)
		#setup_placed.emit(p.player_id, v_key, e_key)

## ---------- Main loop ----------
func _main_loop() -> void:
	if debug_verbose: print("[Economy] main loop")
	while is_running:
		if debug_verbose: print("[Economy] start main loop")

		var pid: int = players[current_player_index].player_id
		_awaiting_player_id = pid

		var roll: int = randi_range(1, 6) + randi_range(1, 6)
		dice_rolled.emit(roll)
		if debug_verbose:
			print("[Economy] need to distribute resources on dice roll of", roll)

		if roll != 7:
			_distribute_resources_for_roll(roll)
			resources_distributed.emit(roll)

		turn_started.emit(pid)   # player hears this and will act
		await turn_ended

		if debug_verbose: print("[Economy] turn ended")

		if not is_setup_phase:
			await get_tree().create_timer(TurnTime).timeout

		current_player_index = (current_player_index + 1) % players.size()

## ---------- Production (robber block + city double payout) ----------
# Returns list of player ids whose inventory changed
func _distribute_resources(roll: int) -> Array[int]:
	if debug_verbose:
		print("[Economy] distributing resources start (roll=", roll, ")")

	# Make sure everyone has an inventory map
	for p in players:
		_ensure_inventory(p.player_id)

	var changed: Array[int] = []

	for p in players:
		var pid := p.player_id
		var added_for_pid := 0

		# All owned settlement vertices for this player
		var verts: Array = world.get_player_settlements(pid) if (world and world.has_method("get_player_settlements")) else []
		for v in verts:
			var mult := 2 if _is_city_at_vertex(v) else 1  # city = x2

			# Ask the world for this vertex's adjacent hex profile; your logs show:
			# { "profile": [ { "resource": "WOOD", "roll": 8, "p": 0.14, ... }, ... ] }
			var prof_v: Variant = world.vertex_resource_profile(v) if (world and world.has_method("vertex_resource_profile")) else null
			if typeof(prof_v) == TYPE_DICTIONARY and (prof_v as Dictionary).has("profile"):
				var arr: Array = (prof_v as Dictionary)["profile"]
				for e in arr:
					if typeof(e) != TYPE_DICTIONARY:
						continue
					var entry: Dictionary = e
					var res := String(entry.get("resource", ""))
					var r   := int(entry.get("roll", 0))
					if r == roll and res != "" and res != "DESERT":
						_give_resource(pid, res, mult)
						added_for_pid += mult
						if debug_very_verbose:
							print("[Economy][PAY] roll=", roll, " pid=", pid, " +", mult, " ", res, " @v=", v)

		if added_for_pid > 0 and not changed.has(pid):
			changed.append(pid)

	if debug_verbose:
		print("[Economy] distributing resources end; changed_pids=", changed)
		_dbg_dump_all_inventories()

	# let HUD/UI react per player
	for pid in changed:
		inventory_changed.emit(pid, inventories[pid])

	return changed



### ---------- AI action (simple heuristic: build one thing) ----------
#func _ai_take_one_action(p: AIEconomyPlayer) -> void:
	## ---- CITY first (upgrade an owned settlement) ----
	#if _can_pay(p.player_id, COST_CITY):
		#var city_targets: Array[Vector2i] = get_legal_city_upgrades(p.player_id)  # <-- 1 arg only
		#if not city_targets.is_empty():
			#var v_key: Vector2i = Vector2i.ZERO
			## Optional chooser on the AI; fallback to first target
			#if p.has_method("choose_city_upgrade"):
				#v_key = p.choose_city_upgrade(world, city_targets)
			#if v_key == Vector2i.ZERO:
				#v_key = city_targets[0]
			#if world.can_place_city(p.player_id, v_key) and request_build_city(p.player_id, v_key, false):
				#_check_win(p.player_id)
				#return
#
	## ---- SETTLEMENT next ----
	#if _can_pay(p.player_id, COST_SETTLEMENT):
		#var targets: Array[Vector2i] = get_legal_settlement_vertices(p.player_id, false)
		#if not targets.is_empty():
			#var v_key: Vector2i = p.choose_settlement_vertex(world)
			#if v_key == Vector2i.ZERO or not world.can_place_settlement(p.player_id, v_key, false):
				#v_key = targets[0]
			#if request_build_settlement(p.player_id, v_key, false):
				#_check_win(p.player_id)
				#return
#
	## ---- ROAD last ----
	#if _can_pay(p.player_id, COST_ROAD):
		#var from_v: Vector2i = _any_vertex_in_network(p.player_id)
		#if from_v != Vector2i.ZERO:
			#var edges: Array[Vector2i] = world._edges_touching_vertex(from_v)
			#for e_key: Vector2i in edges:
				#if request_build_road(p.player_id, e_key, false):
					#return
		#var edges_all: Array[Vector2i] = get_legal_road_edges(p.player_id, false)
		#if not edges_all.is_empty():
			#request_build_road(p.player_id, edges_all[0], false)

# Returns Array[Vector2i] of vertices where this player can upgrade their settlement to a city
func get_legal_city_upgrades(player_id: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []

	var verts: Array = world.settlement_spaces if world != null else []  # <-- explicit : Array
	for v in verts:
		if v.occupied_by == player_id:
			var vk: Vector2i = v.key
			if world.has_method("is_city_at") and world.is_city_at(vk):
				continue
			if world.can_place_city(player_id, vk):
				out.append(vk)
	return out

func _any_vertex_in_network(pid:int) -> Vector2i:
	# Prefer owned settlements
	for v in world.settlement_spaces:
		if v.occupied_by == pid:
			return v.key
	# else endpoints of owned roads
	for e in world.road_spaces:
		if e.occupied_by == pid:
			return e.a
	return Vector2i.ZERO



## ---------- Public build requests (validation lives here) ----------
func request_build_settlement(pid: int, v_key: Vector2i, ignore_connectivity: bool = false) -> bool:
	if not _can_pay(pid, COST_SETTLEMENT):
		build_failed.emit(pid, "settlement", v_key, "cannot_afford")
		return false
	if not world.can_place_settlement(pid, v_key, ignore_connectivity):
		build_failed.emit(pid, "settlement", v_key, "illegal_space")
		return false
	if not world.place_settlement(pid, v_key, ignore_connectivity):
		build_failed.emit(pid, "settlement", v_key, "place_failed")
		return false
	_pay(pid, COST_SETTLEMENT)
	var new_vp: int = int(vp_by_pid.get(pid, 0)) + 1
	vp_by_pid[pid] = new_vp
	vp_changed.emit(pid, new_vp)
	build_success.emit(pid, "settlement", v_key)
	return true
	
# Free placement during setup: enforce distance rule only.
func request_build_settlement_setup(pid: int, v: Vector2i) -> bool:
	if not world or not world.has_method("can_place_settlement_setup"):
		return false
	if not world.can_place_settlement_setup(pid, v):
		build_failed.emit(pid, "settlement", v, "place_failed")
		return false
	if not world.place_settlement_setup(pid, v):
		return false
	# No cost during setup; still grant VP if your rules do
	var new_vp: int = int(vp_by_pid.get(pid, 0)) + 1
	vp_by_pid[pid] = new_vp
	vp_changed.emit(pid, new_vp)
	build_success.emit(pid, "settlement", v)
	return true

	

func request_build_city(pid: int, v_key: Vector2i, ignore_connectivity: bool = false) -> bool:
	if not _can_pay(pid, COST_CITY):
		build_failed.emit(pid, "city", v_key, "cannot_afford")
		return false
	if not world.can_place_city(pid, v_key):
		build_failed.emit(pid, "city", v_key, "illegal_space")
		return false
	if not world.replace_settlement_with_city(pid, v_key):
		build_failed.emit(pid, "city", v_key, "place_failed")
		return false

	_pay(pid, COST_CITY)
	var new_vp: int = int(vp_by_pid.get(pid, 0)) + 1
	vp_by_pid[pid] = new_vp
	vp_changed.emit(pid, new_vp)
	build_success.emit(pid, "city", v_key)
	return true


func request_build_road(pid: int, e_key: Vector2i, ignore_connectivity: bool = false) -> bool:
	if not _can_pay(pid, COST_ROAD):
		build_failed.emit(pid, "road", e_key, "cannot_afford")
		return false
	if not world.can_place_road(pid, e_key, ignore_connectivity):
		build_failed.emit(pid, "road", e_key, "illegal_space")
		return false
	if not world.place_road(pid, e_key, ignore_connectivity):
		build_failed.emit(pid, "road", e_key, "place_failed")
		return false
	_pay(pid, COST_ROAD)
	build_success.emit(pid, "road", e_key)
	return true

## ---------- Legal candidate helpers for AI ----------
func get_legal_settlement_vertices(pid: int, ignore_connectivity: bool = false) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for v in world.settlement_spaces:
		if world.can_place_settlement(pid, v.key, ignore_connectivity):
			out.append(v.key)
	return out

func get_legal_road_edges(pid: int, ignore_connectivity: bool = false) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for e in world.road_spaces:
		if world.can_place_road(pid, e.key, ignore_connectivity):
			out.append(e.key)
	return out

## ---------- Inventory helpers ----------
func _can_pay(pid: int, cost: Dictionary) -> bool:
	var inv: Dictionary = inventories.get(pid, null)
	if inv == null:
		return false
	for k in cost.keys():
		if int(inv.get(k, 0)) < int(cost[k]):
			return false
	return true

func _pay(pid: int, cost: Dictionary) -> void:
	var inv: Dictionary = inventories.get(pid, null)
	if inv == null: return
	for k in cost.keys():
		inv[k] = int(inv.get(k, 0)) - int(cost[k])
	if debug_verbose:
		inventory_changed.emit(pid, inv)


## ---------- VP / win ----------
func _check_win(pid:int) -> void:
	if int(vp_by_pid.get(pid, 0)) >= WIN_POINTS:
		is_running = false
		winner.emit(pid)

## ---------- Introspection (optional) ----------
func get_inventory(pid: int) -> Dictionary:
	return inventories.get(pid, {"WOOD":0,"BRICK":0,"WHEAT":0,"SHEEP":0,"ORE":0})

func get_vp(pid: int) -> int:
	return int(vp_by_pid.get(pid, 0))

func get_all_inventories() -> Dictionary:
	var snap: Dictionary = {}
	for pid in inventories.keys():
		# make a shallow copy so UI can read safely
		var inv: Dictionary = inventories[pid]
		snap[pid] = {
			"WOOD": int(inv["WOOD"]),
			"BRICK": int(inv["BRICK"]),
			"WHEAT": int(inv["WHEAT"]),
			"SHEEP": int(inv["SHEEP"]),
			"ORE": int(inv["ORE"])
		}
	return snap

func debug_dump_inventories() -> void:
	var snap := get_all_inventories()
	inventories_dumped.emit(snap)

# Add to Economy.gd after the inventory helpers section

## ---------- Trading system ----------
func can_trade(pid: int, offer: Dictionary, request: Dictionary) -> bool:
	var inv = inventories.get(pid, {})
	
	# Check if player has enough resources to offer
	for resource in offer:
		if inv.get(resource, 0) < offer[resource]:
			return false
	
	return true

func execute_trade(pid: int, offer: Dictionary, request: Dictionary) -> bool:
	if not can_trade(pid, offer, request):
		return false
	
	# Remove offered resources
	for resource in offer:
		inventories[pid][resource] = int(inventories[pid][resource]) - offer[resource]
	
	# Add requested resources
	for resource in request:
		inventories[pid][resource] = int(inventories[pid].get(resource, 0)) + request[resource]
	
	if debug_verbose:
		inventory_changed.emit(pid, inventories[pid])
	
	return true

func execute_bank_trade(pid: int, offer: Dictionary, request: Dictionary, harbor_rate: int = TRADE_RATE_GENERIC) -> bool:
	# Check if trade ratio is valid
	for resource in offer:
		if offer[resource] % harbor_rate != 0:
			return false
		if offer[resource] / harbor_rate != request.values()[0] if request.size() == 1 else false:
			return false
	
	if not can_trade(pid, offer, request):
		return false
	
	return execute_trade(pid, offer, request)

# Get the best trade rate for a player for a specific resource
func get_trade_rate(pid: int, resource: String) -> int:
	# TODO: Implement harbor checking logic
	# For now, return generic rate
	return TRADE_RATE_GENERIC

# Player-to-player trading
func propose_trade(pid: int, partner_pid: int, offer: Dictionary, request: Dictionary) -> void:
	if can_trade(pid, offer, request):
		trade_offered.emit(pid, offer, request)
		# In a real implementation, you'd store the trade proposal and wait for response

func accept_trade(pid: int, partner_pid: int, offer: Dictionary, request: Dictionary) -> bool:
	# The partner is offering resources, so we reverse offer/request for them
	if can_trade(partner_pid, offer, request) and can_trade(pid, request, offer):
		# Execute both sides of the trade
		execute_trade(partner_pid, offer, request)
		execute_trade(pid, request, offer)
		trade_completed.emit(pid, partner_pid, offer, request)
		return true
	return false
	_compute_ai_class_list_exact

func _filled_array(klass, n: int) -> Array:
	var arr: Array = []
	for _i in range(n):
		arr.append(klass)
	return arr

func _on_player_turn_finished(pid: int) -> void:
	if pid != _awaiting_player_id:
		if debug_verbose:
			print("[Economy][WARN] unexpected finish from", pid, "awaiting", _awaiting_player_id)
		return
	_awaiting_player_id = -1
	turn_ended.emit(pid)
