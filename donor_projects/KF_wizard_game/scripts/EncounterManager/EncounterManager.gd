extends Node3D
class_name EncounterManager
var _ai_encounter: CardCombatEncounter = null
var _combat_timer: Timer = null
var _dbg_inrange: Dictionary = {}  # id -> true
var _inrange_prev: Dictionary = {}  # id -> Node3D
var _near_prev: Dictionary = {}  # id -> Node3D

@export var debug_verbose := false

var _player: Node3D = null
const ENCOUNTER_UI_SCENE: PackedScene = preload("res://scenes/ui/EncounterUI.tscn")
var _ui: EncounterUI = null
const CHARACTER_GROUP := "characters"
var _queued_player_encounter: Array = []
@export var encounter_ui_scene: PackedScene
var _saved_mouse_mode: int = Input.MOUSE_MODE_VISIBLE
var _encounter_target: Node3D = null

var _encounter_ui: EncounterUI
var _pending_player_participants: Array = []

var _use_global_pause := true  # flip to false if you prefer per-actor locking



signal encounter_started(participants: Array)
signal encounter_ended(participants: Array)
signal proximity_alert(a: Node3D, b: Node3D, distance: float)

@export var debug_sample_overlaps: bool = false   # periodic overlap dump
var _dbg_accum: float = 0.0


@export var detection_radius: float = 5.0
@export var ai_scan_interval: float = 0.5
@export var min_pair_cooldown: float = 6.0
@export var human_player_path: NodePath
var _players := []                # Array of Node3D
var _probes := {}                 # player -> Area3D

var _pair_cooldowns := {}    # key "idA|idB" -> time remaining
var _active := false
var _scan_accum := 0.0
var _current_encounter: Encounter = null

func _ready() -> void:
	add_to_group("encounter_manager")  # lets others find us safely
	if debug_verbose:
		print("[EM][READY] detection_radius=", detection_radius)
	# Optional: watch for players appearing/disappearing, purely for debug
	get_tree().node_added.connect(_em_node_added)
	get_tree().node_removed.connect(_em_node_removed)

	if debug_verbose:
		print("[EncounterManager] ready; radius=%.2f" % detection_radius)
	# Seed existing players
	for p in get_tree().get_nodes_in_group("player"):
		_register_player(p)

	# Track future joins/leaves
	get_tree().node_added.connect(_on_node_added_mp)
	get_tree().node_removed.connect(_on_node_removed_mp)
	# Try to find player if not assigned
	if human_player_path != NodePath():
		_player = get_node_or_null(human_player_path)
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	# Ensure an Area3D exists for player proximity
	_ensure_detection_area()
	# Tweak area radius
	_apply_radius()
	if debug_verbose:
		print("[EM][READY] detection_radius=", detection_radius)

	# Show which player we resolved
	if is_instance_valid(_player):
		if debug_verbose: print("[EM][READY] player=", _player.name, " pos=", _player.global_position)
	else:
		if debug_verbose: print("[EM][READY] player=NULL (player vs NPC encounters cannot trigger)")

	# Dump detection area configuration
	var a3 := get_node_or_null("DetectionArea") as Area3D
	if a3:
		var rad := -1.0
		var cs := a3.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if cs and cs.shape is SphereShape3D:
			rad = (cs.shape as SphereShape3D).radius
		var lay := 0
		var msk := 0
		# Area3D is a CollisionObject3D, so these always exist
		lay = a3.collision_layer
		msk = a3.collision_mask
		if debug_verbose: print("[EM][AREA] monitoring=", a3.monitoring, " radius=", rad, " layer=", lay, " mask=", msk)
	else:
		if debug_verbose: print("[EM][AREA] MISSING DetectionArea (no proximity checks will run)")

func _resolve_character_root(n: Object) -> Character3D:
	var cur := n as Node
	while cur:
		if cur is Character3D:
			return cur
		cur = cur.get_parent()
	return null

func _co3d_layer(o: Object) -> int:
	if o is CollisionObject3D:
		return (o as CollisionObject3D).collision_layer
	return 0

func _co3d_mask(o: Object) -> int:
	if o is CollisionObject3D:
		return (o as CollisionObject3D).collision_mask
	return 0

func _safe_name(o: Object) -> String:
	if o is Node:
		return (o as Node).name
	return "<non-node>"


func _dbg_as_character(node: Object) -> Character3D:
	var n := node as Node
	while n:
		if n is Character3D:
			return n
		n = n.get_parent()
	return null


func _stop_ai_combat() -> void:
	if _combat_timer and _combat_timer.is_stopped() == false:
		_combat_timer.stop()
	if _ai_encounter:
		_ai_encounter.end()
	_ai_encounter = null

func _on_player_proximity(npc: Node3D) -> void:
	# Give the player priority: stop AI combat if it’s running
	if _ai_encounter:
		print("[EM] preempting AI combat for player prompt")
		_stop_ai_combat()
	# Skip the queuing logic and show the player prompt immediately
	if _player and is_instance_valid(npc):
		_show_player_ui([_player, npc])

func _on_ui_leave() -> void:
	if debug_verbose: print("[EncounterManager] player chose leave")
	if _encounter_ui: _encounter_ui.hide_ui()
	_end_and_unfreeze()

func _on_ui_talk() -> void:
	if debug_verbose: print("[EncounterManager] player chose talk")
	if _encounter_ui: _encounter_ui.hide_ui()
	_end_and_unfreeze()
	# TODO: start dialogue

func _on_ui_fight() -> void:
	if debug_verbose: print("[EncounterManager] player chose fight")
	# Make sure the tree is unpaused before we start a timer-driven encounter.
	get_tree().paused = false

	# Keep actors locked so they don't wander during card combat.
	# (If you prefer unlocking, remove these two lines.)
	var other := _get_other_participant(_pending_player_participants)
	_lock_participant(_player, true)
	_lock_participant(other, true)

	if _encounter_ui:
		_encounter_ui.hide_ui()

	_start_player_card_combat(_pending_player_participants)


func _end_and_unfreeze() -> void:
	if _use_global_pause:
		get_tree().paused = false
	# restore mouse mode
	Input.set_mouse_mode(_saved_mouse_mode)
	# unlock
	var other := _get_other_participant(_pending_player_participants)
	_lock_participant(_player, false)
	_lock_participant(other, false)
	_current_encounter = null

func _close_ui_and_unfreeze() -> void:
	if _encounter_ui: _encounter_ui.hide_ui()
	if _use_global_pause: get_tree().paused = false
	var other := _get_other_participant(_pending_player_participants)
	_lock_participant(_player, false)
	_lock_participant(other, false)





func _ensure_detection_area() -> void:
	if not has_node("DetectionArea"):
		var a := Area3D.new()
		a.name = "DetectionArea"
		add_child(a)
	var a3 := $DetectionArea as Area3D
	if not a3.has_node("CollisionShape3D"):
		var cs := CollisionShape3D.new()
		a3.add_child(cs)
	var cs3 := $DetectionArea/CollisionShape3D as CollisionShape3D
	if cs3.shape == null:
		cs3.shape = SphereShape3D.new()
	a3.body_entered.connect(_on_area_body_entered, CONNECT_DEFERRED | CONNECT_PERSIST)
	a3.body_exited.connect(_on_area_body_exited, CONNECT_DEFERRED | CONNECT_PERSIST)
	## Added for extra players
	# Follow
	for p in _players:
		if not is_instance_valid(p):
			continue
		if _probes.has(p):
			var a := _probes[p] as Area3D
			if is_instance_valid(a):
				a.global_position = p.global_position
				var cs := a.get_node_or_null("CollisionShape3D") as CollisionShape3D
				if cs and cs.shape is SphereShape3D:
					var sph := cs.shape as SphereShape3D
					if abs(sph.radius - detection_radius) > 0.01:
						sph.radius = detection_radius

	

func _apply_radius() -> void:
	var cs3 := $DetectionArea/CollisionShape3D as CollisionShape3D
	if cs3 and cs3.shape is SphereShape3D:
		(cs3.shape as SphereShape3D).radius = detection_radius

func _physics_process(delta: float) -> void:
	# Follow the player (so their proximity triggers the area)
	if _player and is_instance_valid(_player):
		global_position = _player.global_position
	# Cooldown ticking
	for k in _pair_cooldowns.keys():
		_pair_cooldowns[k] = max(0.0, float(_pair_cooldowns[k]) - delta)
	# Periodic AI vs AI scan
	_scan_accum += delta
	if _scan_accum >= ai_scan_interval:
		_scan_accum = 0.0
		_scan_for_ai_encounters()
	if debug_sample_overlaps and is_instance_valid(_player):
		var a3 := get_node_or_null("DetectionArea") as Area3D
		if a3:
			_dbg_accum += delta
			if _dbg_accum >= 1.0:
				_dbg_accum = 0.0
				var bodies := a3.get_overlapping_bodies()
				if debug_verbose: print("[EM][OVERLAP] count=", bodies.size())
				for b in bodies:
					if b is Node3D:
						var pb := (b as Node3D).global_position
						var pa := _player.global_position
						var d2d := Vector2(pb.x, pb.z).distance_to(Vector2(pa.x, pa.z))
						var lay := 0
						var msk := 0
						if b is CollisionObject3D:
							lay = (b as CollisionObject3D).collision_layer
							msk = (b as CollisionObject3D).collision_mask
						if debug_verbose: print("   - ", (b as Node).name, " d2d=", d2d, " layer=", lay, " mask=", msk)
	_scan_player_overlaps_and_trigger_enters()
	_scan_player_distance_enters()

func _scan_for_ai_encounters() -> void:
	if _current_encounter != null:
		return
	if _queued_player_encounter.size() >= 2:
		return  # give priority to pending player encounter
	var chars: Array = get_tree().get_nodes_in_group("characters")
	for i in range(chars.size()):
		var a: Node3D = chars[i] as Node3D
		if a == null or a == _player:
			continue
		for j in range(i + 1, chars.size()):
			var b: Node3D = chars[j] as Node3D
			if b == null or b == _player:
				continue
			if not (is_instance_valid(a) and is_instance_valid(b)):
				continue
			var d: float = a.global_position.distance_to(b.global_position)
			if d <= detection_radius:
				if _pair_ready(a, b):
					if debug_verbose:
						print("[EncounterManager] AI proximity ", a.name, " <-> ", b.name, " d=%.2f" % d)
					proximity_alert.emit(a, b, d)
					_begin_encounter([a, b])
					return

func _on_area_body_entered(body: Node) -> void:
	# Resolve child shapes (e.g., "Collider") up to the Character3D root
	var target := _resolve_character_root(body)
	if target == null:
		if debug_verbose:
			print("[EM][ENTER] drop non-character root: ", _safe_name(body))
		return

	if not target.is_in_group(CHARACTER_GROUP):
		if debug_verbose:
			print("[EM][ENTER] drop non-'characters' root: ", target.name)
		return

	if _player == null or not is_instance_valid(_player): return
	if target == _player: return

	# 2D ground-plane distance (matches your overlap prints)
	var pa := _player.global_position
	var pb := target.global_position
	var d2d := Vector2(pa.x, pa.z).distance_to(Vector2(pb.x, pb.z))
	if d2d > detection_radius: return
	if not _pair_ready(_player, target): return

	if debug_verbose:
		print("[EncounterManager] Player proximity ", _player.name, "<->", target.name, " d=%.2f" % d2d)
	proximity_alert.emit(_player, target, d2d)
	_on_player_proximity(target)

func _on_area_body_exited(_body: Node) -> void:
	pass

func _pair_key(a: Object, b: Object) -> String:
	var ia := a.get_instance_id()
	var ib := b.get_instance_id()
	if ia > ib:
		var tmp = ia; ia = ib; ib = tmp
	return str(ia) + "|" + str(ib)


# Put this helper anywhere in EncounterManager.gd (e.g. above _pair_ready).
func _dbg_node_info(o: Object) -> String:
	if o == null:
		return "<null>"

	var name_str := "<non-node>"
	if o is Node:
		name_str = (o as Node).name

	var cls := o.get_class()
	var is_char := (o is Character3D)

	var groups := []
	if o is Node:
		for g in (o as Node).get_groups():
			groups.append(str(g))

	var layer := 0
	var mask := 0
	if o is CollisionObject3D:
		layer = (o as CollisionObject3D).collision_layer
		mask  = (o as CollisionObject3D).collision_mask

	return "%s cls=%s char=%s groups=%s L=%s M=%s" % [name_str, cls, is_char, groups, layer, mask]


func _pair_ready(a: Object, b: Object) -> bool:
	if debug_verbose: print("[EM] checking pair ready")
	var k := _pair_key(a, b)
	if a._encounter_locked or b._encounter_locked:
		if debug_verbose: print("[EM] pair not ready, one is locked")
		return false

	var cd := 0.0
	if _pair_cooldowns.has(k):
		cd = float(_pair_cooldowns[k])

	if debug_verbose:
		var a_info := _dbg_node_info(a)
		var b_info := _dbg_node_info(b)
		print("[EM][PAIR?] key=", k, " cd=", "%.2f" % cd)
		print("[EM][PAIR?]   a=", a_info)
		print("[EM][PAIR?]   b=", b_info)

		# Distance (only if both are valid Node3D)
		var dist_logged := false
		if a is Node3D and b is Node3D and is_instance_valid(a) and is_instance_valid(b):
			var d := (a as Node3D).global_position.distance_to((b as Node3D).global_position)
			print("[EM][PAIR?]   distance=", "%.2f" % d, " thresh=", detection_radius)
			dist_logged = true

		# Would-block reasons (informational only; DOES NOT change return)
		var reasons: Array = []

		if a == null or b == null:
			reasons.append("null")
		elif a == b:
			reasons.append("same-node")

		if not (a is Character3D):
			reasons.append("a-not-Character3D")
		if not (b is Character3D):
			reasons.append("b-not-Character3D")

		if a is Node and (a as Node).is_in_group("dead"):
			reasons.append("a-dead")
		if b is Node and (b as Node).is_in_group("dead"):
			reasons.append("b-dead")

		if a != null and a.has_meta("encounter_locked") and a.get_meta("encounter_locked"):
			reasons.append("a-locked")
		if b != null and b.has_meta("encounter_locked") and b.get_meta("encounter_locked"):
			reasons.append("b-locked")

		if not dist_logged and a is Node3D and b is Node3D:
			var d2 := (a as Node3D).global_position.distance_to((b as Node3D).global_position)
			if d2 > detection_radius:
				reasons.append("distance")
		elif a is Node3D and b is Node3D:
			# We already logged distance; repeat the check without reprinting
			var d3 := (a as Node3D).global_position.distance_to((b as Node3D).global_position)
			if d3 > detection_radius:
				reasons.append("distance")

		if cd > 0.0:
			reasons.append("cooldown")

		if reasons.size() > 0:
			print("[EM][PAIR?]   would_block=", reasons)
		else:
			print("[EM][PAIR?]   would_allow")

		print("[EM][PAIR?]   cooldowns.size=", _pair_cooldowns.size())

	if cd > 0.0 and debug_verbose:
		print("[EM][CD] block ", k, " remaining=", cd)

	return cd <= 0.0


#func _pair_ready(a: Object, b: Object) -> bool:
	#var k := _pair_key(a, b)
	#var cd := float(_pair_cooldowns.get(k, 0.0))
	#if _pair_cooldowns.has(k):
		#cd = float(_pair_cooldowns[k])
	#if cd > 0.0 and debug_verbose:
		#print("[EM][CD] block ", k, " remaining=", cd)
	#return cd <= 0.0

func _arm_pair_cooldown(a: Object, b: Object) -> void:
	var k := _pair_key(a, b)
	_pair_cooldowns[k] = min_pair_cooldown

func _begin_encounter(participants: Array) -> void:
	if debug_verbose:
		var names := ""
		for p in participants:
			if p is Node:
				names += (p as Node).name + " "
			else:
				names += "<?> "
		print("[EM][BEGIN] participants=", names)

	var involves_player := _player != null and participants.has(_player)

	# If something is running, queue player encounter instead of dropping it.
	if _current_encounter != null:
		if involves_player:
			_queued_player_encounter = participants.duplicate()
			if debug_verbose:
				print("[EM] queued player encounter (AI combat in progress)")
		else:
			if debug_verbose:
				print("[EncounterManager] Encounter already running; ignoring new request")
		return

	if participants.size() < 2:
		return

	_arm_pair_cooldown(participants[0], participants[1])
	encounter_started.emit(participants)

	if involves_player:
		_show_player_ui(participants)
	else:
		_start_ai_combat(participants)

func _start_ai_combat(participants: Array) -> void:
	if debug_verbose:
		var _names := []
		for _p in participants:
			_names.append(_p.name)
		print("[EncounterManager] AI card-combat starting for ", _names)

	for p in participants:
		if p.combat_profile == null:
			var fallback := CombatProfile.new()
			p.combat_profile = fallback

	var ce: CardCombatEncounter = CardCombatEncounter.new()
	ce.set_participants(participants)
	_ai_encounter = ce          # ✅ track AI encounter
	_current_encounter = ce
	ce.start()

	var done_now := ce.step()
	if done_now:
		_end_encounter(participants)
		return

	var t := Timer.new()
	t.one_shot = false
	t.wait_time = 0.35
	add_child(t)
	t.timeout.connect(func ():
		var finished_round := ce.step()
		if finished_round:
			t.stop()
			t.queue_free()
			_end_encounter(participants)
	)
	t.start()
	if debug_verbose:
		print("[EncounterManager] combat timer started (wait_time=%.2f)" % t.wait_time)

func _dismiss_ui() -> void:
	if _ui and is_instance_valid(_ui):
		_ui.queue_free()
	_ui = null

func _end_encounter(participants: Array) -> void:
	if debug_verbose:
		print("[EncounterManager] encounter end; unlocking participants")

	# Unlock NPCs
	for p in participants:
		if p and is_instance_valid(p) and p.has_method("set_encounter_locked"):
			p.set_encounter_locked(false)
	# Unlock player
	if _player and _player.has_method("set_controls_locked"):
		_player.set_controls_locked(false)

	_current_encounter = null
	encounter_ended.emit(participants)

	# If we queued a player encounter, run it now (and block new AI fights).
	if _queued_player_encounter.size() >= 2:
		var valid := true
		for n in _queued_player_encounter:
			if n == null or not is_instance_valid(n):
				valid = false
				break
		if valid and _queued_player_encounter.has(_player):
			var q := _queued_player_encounter.duplicate()
			_queued_player_encounter.clear()
			_begin_encounter(q)
		else:
			_queued_player_encounter.clear()
	_ai_encounter = null

func _register_player(n: Node) -> void:
	if not (n is Node3D):
		return
	var p := n as Node3D
	if _players.has(p):
		return
	_players.append(p)
	_attach_probe_for(p)
	if debug_verbose:
		print("[EM] player registered: ", p.name)
	_player = p
	if debug_verbose:
		var groups := []
		for g in p.get_groups():
			groups.append(str(g))
		print("[EM][PLAYER] set ->", p.name,
			" in_groups=", groups,
			" class=", p.get_class(),
			" extends Character3D=", (p is Character3D),
			" layer=", p.collision_layer, " mask=", p.collision_mask)

func _unregister_player(n: Node) -> void:
	if not (n is Node3D):
		return
	var p := n as Node3D
	if not _players.has(p):
		return
	_players.erase(p)
	if _probes.has(p):
		var a := _probes[p] as Area3D
		if is_instance_valid(a):
			a.queue_free()
		_probes.erase(p)
	if debug_verbose:
		print("[EM] player unregistered: ", p.name)

func _on_node_added_mp(n: Node) -> void:
	if n.is_in_group("player"):
		_register_player(n)

func _on_node_removed_mp(n: Node) -> void:
	if n.is_in_group("player"):
		_unregister_player(n)

func _attach_probe_for(player: Node3D) -> void:
	var area := Area3D.new()
	area.name = "EM_Probe_" + str(player.get_instance_id())

	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = detection_radius
	cs.shape = sph
	area.add_child(cs)

	area.collision_layer = 0
	area.collision_mask = 1   # see default layer; we’ll filter by group below
	area.monitoring = true
	area.monitorable = false

	add_child(area)
	_probes[player] = area
	area.body_entered.connect(_on_probe_body_entered.bind(player))

	if debug_verbose:
		print("[EM] probe attached for ", player.name, " radius=", detection_radius)

func _on_probe_body_entered(player: Node3D, body: Node) -> void:
	if debug_verbose:
		print("[EM][ENTER] raw body=", body.name,
			" class=", body.get_class(),
			" is Character3D=", (body is Character3D),
			" in 'characters'=", body.is_in_group(CHARACTER_GROUP) if body.has_method("is_in_group") else "n/a",
			" layer=", (body.collision_layer if body.has_method("get_class") else "n/a"),
			" mask=", (body.collision_mask if body.has_method("get_class") else "n/a"))
	# keep your existing early-returns/checks below
	if not (body is Node3D): return
	if not body.is_in_group(CHARACTER_GROUP): return
	if body == player: return

	var pa := player.global_position
	var pb := (body as Node3D).global_position
	var d2d := Vector2(pa.x, pa.z).distance_to(Vector2(pb.x, pb.z))
	if d2d > detection_radius: return
	if not _pair_ready(player, body): return

	if debug_verbose:
		print("[EM] Player proximity ", player.name, " <-> ", (body as Node).name, " d=", d2d)
	if player == _player:
		_on_player_proximity(body as Node3D)
	else:
		_begin_encounter([player, body]) # for split-screen or future players
	

func register_human_player(p: Node3D) -> void:
	_player = p
	if debug_verbose and is_instance_valid(_player):
		print("[EM] player registered: ", _player.name, " path=", _player.get_path())

# Debug-only helpers (don’t change encounter logic)
func _em_node_added(n: Node) -> void:
	if n.is_in_group("player"):
		if debug_verbose: print("[EM][DEBUG] node_added saw a player: ", n.name)

func _em_node_removed(n: Node) -> void:
	if n == _player:
		if debug_verbose: print("[EM][DEBUG] player removed: ", n.name)
		_player = null

func _start_player_card_combat(participants: Array) -> void:
	# TEMP: start the same combat flow the AI uses
	# (you’ll replace this with a human-controlled CardCombat soon)
	_start_ai_combat(participants)

func _face_camera_on(target: Node) -> void:
	if target == null or not is_instance_valid(_player):
		return
	var cam: Camera3D = _player.get_node_or_null("Camera3D")
	if cam == null or not (target is Node3D):
		return

	var start := cam.global_transform
	var end := start.looking_at((target as Node3D).global_transform.origin, Vector3.UP)
	var tw := create_tween()
	tw.tween_property(cam, "global_transform", end, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _end_player_encounter(unfreeze_player: bool) -> void:
	if _ui != null:
		_ui.queue_free()
		_ui = null

	Input.set_mouse_mode(_saved_mouse_mode)

	if unfreeze_player and is_instance_valid(_player):
		if _player.has_method("set_input_enabled"):
			_player.call("set_input_enabled", true)

	_encounter_target = null

func _lock_participant(n: Node, lock: bool) -> void:
	if n == null or not is_instance_valid(n):
		return

	# Call your character-level locks first (these should block input & AI)
	if n.has_method("set_controls_locked"):
		n.call("set_controls_locked", lock)
	if n.has_method("set_encounter_locked"):
		n.call("set_encounter_locked", lock)

	# If there is a NavigationAgent3D child, make it passive and kill its path.
	var agent := n.get_node_or_null("NavigationAgent3D") as NavigationAgent3D
	if agent == null:
		# try to find one by type if it's not named literally "NavigationAgent3D"
		for c in n.get_children():
			if c is NavigationAgent3D:
				agent = c
				break

	if agent:
		# Agents don’t have `enabled`. Do this instead:
		agent.avoidance_enabled = not lock          # stop steering/avoidance
		if lock:
			# cancel any movement intent
			if n is Node3D:
				agent.target_position = (n as Node3D).global_position
			# if your mover reads velocity from the agent, zero it:
			agent.velocity = Vector3.ZERO
		# also stop the node’s processing as an extra belt-and-braces
		agent.set_process(not lock)
		agent.set_physics_process(not lock)

	# Optional: pause any obvious AI node under the character
	var ai := n.get_node_or_null("AI")
	if ai:
		ai.set_process(not lock)
		ai.set_physics_process(not lock)

	var status := "LOCKED" if lock else "UNLOCKED"
	var agent_desc := " (agent ok)" if agent != null else " (no agent)"
	print("[EM] ", n.name, " ", status, agent_desc)




func _show_player_ui(participants: Array) -> void:
	_pending_player_participants = participants.duplicate()

	_saved_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Make/keep a single UI instance
	if _encounter_ui == null:
		var scene: PackedScene = encounter_ui_scene
		if scene == null:
			scene = ENCOUNTER_UI_SCENE
		_encounter_ui = scene.instantiate() as EncounterUI
		add_child(_encounter_ui)
		_encounter_ui.chose_dialogue.connect(_on_ui_talk)
		_encounter_ui.chose_combat.connect(_on_ui_fight)
		_encounter_ui.chose_leave.connect(_on_ui_leave)
		if debug_verbose:
			print("[EM] EncounterUI instantiated and signals connected")

	# UI must run while paused
	_encounter_ui.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	var other := _get_other_participant(participants)
	var other_name: String = (str(other.name)) if is_instance_valid(other) else "someone"

	# Freeze actors (and optionally the whole world)
	_lock_participant(_player, true)
	_lock_participant(other, true)

	if _use_global_pause:
		get_tree().paused = true

	var prompt := "You encounter %s. [R] Talk  [T] Fight  [Y] Leave" % other_name
	if debug_verbose:
		print("[EncounterManager] showing UI for player encounter vs ", other_name, " paused=", get_tree().paused, " ui.pm=", _encounter_ui.process_mode)
	_encounter_ui.show_with_prompt(prompt)

	_face_camera_on(other)

func _get_other_participant(participants: Array) -> Node:
	for p in participants:
		if p != _player:
			return p
	return null

func _dbg_is_ground(n: Node) -> bool:
	# Tweak these to match your nodes/groups.
	if n is StaticBody3D:
		# Your ground/hex tiles appear as StaticBody3D
		return true
	if n.is_in_group("terrain") or n.is_in_group("ground") or n.is_in_group("hex"):
		return true
	# Name heuristics to catch tiles/skirts/etc.
	var nm := n.name
	return nm.begins_with("Hex") or nm.begins_with("Tile") or nm.begins_with("Ground")

func _dbg_print_overlaps() -> void:
	if not debug_verbose:
		return

	# Collect the areas we want to inspect: the main DetectionArea and (if any) the player's probe.
	var areas: Array[Area3D] = []
	var a3 := get_node_or_null("DetectionArea") as Area3D
	if a3 != null:
		areas.append(a3)

	if _player != null and _probes.has(_player):
		var probe := _probes[_player] as Area3D
		if probe != null and probe != a3:
			areas.append(probe)

	if areas.size() == 0:
		return

	for area in areas:
		# get_overlapping_bodies() returns Array; declare it so the editor is happy.
		var bodies: Array = area.get_overlapping_bodies()
		var useful: Array[Node] = []

		for b in bodies:
			var n := b as Node
			if n != null and not _dbg_is_ground(n) and n.name != "PlayerCharacter":
				useful.append(n)

		if useful.size() == 0:
			continue

		print("[EM][OVERLAP]", area.name, " useful=", useful.size())
		for n in useful:
			var d2d := 0.0
			if _player != null and n is Node3D:
				d2d = _player.global_position.distance_to((n as Node3D).global_position)
			var lay := _co3d_layer(n)
			var msk := _co3d_mask(n)
			print("   - ", n.name, " d2d=", d2d, " layer=", lay, " mask=", msk)

func _on_probe_body_entered_debug(body: Node) -> void:
	if not debug_verbose:
		return
	var resolved := _dbg_as_character(body)
	var resolved_name := "null"
	if resolved != null:
		resolved_name = resolved.name
	print("[EM][ENTER] raw=", _safe_name(body),
		  " class=", body.get_class(),
		  " is Character3D=", (body is Character3D),
		  " resolved_char=", resolved_name)
	# NOTE: this function is just for logging; it is NOT connected anywhere.


func _dbg_watch_player_contacts() -> void:
	if not debug_verbose: return
	if _player == null: return

	# Scan characters within radius
	var now: Dictionary = {}
	var chars: Array = get_tree().get_nodes_in_group(CHARACTER_GROUP)
	for n in chars:
		var c := n as Node3D
		if c == null or c == _player: continue
		var d := _player.global_position.distance_to(c.global_position)
		if d <= detection_radius:
			now[c.get_instance_id()] = c

	# Log “would enter” (present now, absent before)
	for id in now.keys():
		if not _dbg_inrange.has(id):
			var c := now[id] as Node3D
			print("[EM][DBG] WOULD_ENTER ", c.name)

	# Log “would exit” (was in before, now out)
	for id in _dbg_inrange.keys():
		if not now.has(id):
			var c := _dbg_inrange[id] as Node3D
			print("[EM][DBG] WOULD_EXIT ", c.name)

	_dbg_inrange = now

func _scan_player_overlaps_and_trigger_enters() -> void:
	if _player == null or not is_instance_valid(_player):
		_inrange_prev.clear()
		return

	var area := get_node_or_null("DetectionArea") as Area3D
	if area == null:
		return

	# Build the "now" set from actual overlaps, resolving child colliders.
	var now: Dictionary = {}
	var bodies: Array = area.get_overlapping_bodies()
	for b in bodies:
		var root := _resolve_character_root(b)
		if root == null: continue
		if root == _player: continue
		if not root.is_in_group(CHARACTER_GROUP): continue
		now[root.get_instance_id()] = root

	# Treat new entries as "enter" events (this compensates for the area moving).
	for id in now.keys():
		if not _inrange_prev.has(id):
			var target := now[id] as Node3D
			# Distance/cooldown gates (same as the signal handler)
			var pa := _player.global_position
			var pb := target.global_position
			var d2d := Vector2(pa.x, pa.z).distance_to(Vector2(pb.x, pb.z))
			if d2d <= detection_radius and _pair_ready(_player, target):
				if debug_verbose:
					print("[EM][SNET] ENTER ", _player.name, "<->", target.name, " d=%.2f" % d2d)
				proximity_alert.emit(_player, target, d2d)
				_on_player_proximity(target)

	_inrange_prev = now

func _d2d(a: Node3D, b: Node3D) -> float:
	return Vector2(a.global_position.x, a.global_position.z).distance_to(
		Vector2(b.global_position.x, b.global_position.z))


func _scan_player_distance_enters() -> void:
	# If no player, clear and bail
	if _player == null or not is_instance_valid(_player):
		_near_prev.clear()
		return

	# Build "now" set of in-range characters by distance alone
	var now: Dictionary = {}
	var chars: Array = get_tree().get_nodes_in_group(CHARACTER_GROUP)
	for n in chars:
		var c := n as Node3D
		if c == null: continue
		if c == _player: continue
		# Optional: respect any "dead"/locked flags you log in _pair_ready
		if c.has_meta("encounter_locked") and c.get_meta("encounter_locked"): continue
		var d := _d2d(_player, c)
		if d <= detection_radius:
			now[c.get_instance_id()] = c

	# Fire "enter" for newly in-range NPCs
	for id in now.keys():
		if not _near_prev.has(id):
			var target := now[id] as Node3D
			# Keep your cooldown & gating exactly the same
			if _pair_ready(_player, target):
				if debug_verbose:
					print("[EM][DIST] ENTER ", _player.name, "<->", target.name,
						" d=%.2f" % _d2d(_player, target))
				# Respect your encounter queue/rules
				_on_player_proximity(target)

	# Update previous set
	_near_prev = now
