# Character3D.gd (null-safe NavigationAgent3D for Godot 4.4.1)
extends CharacterBody3D
class_name Character3D

@export var debug_verbose: bool = false
@export var debug_draw_path: bool = false

# --- Behavior & tuning ---
@export var faction: int = 0
@export var move_speed: float = 3
@export var seek_interval_sec: float = 0.4
@export var vision_radius: float = 480.0
@export var ignore_radius_for_acquire: bool = false


@export var hover_height: float = 0.1             # how much to float above the hit point
@export var ground_max_check: float = 30.0        # how far up/down we look for ground
@export_flags_3d_physics var ground_mask := 1     # collision mask for “ground” (set to your floor’s layer)
var _handling_nav_signal := false
@export var min_retarget_delay := 0.05     # a single-tick debounce
@export var min_set_target_distance := 1.0 # don't set targets closer than this

const AbstractWorld := preload("res://scripts/game/AbstractWorld.gd") # type hint for world lookup

@export var _encounter_locked: bool = false
var _is_dead: bool = false
@export var runtime_health: int = 0

@export var combat_profile: CombatProfile
var deck_runtime: DeckRuntime

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var _label3d: Label3D = get_node_or_null("Label3D")
@onready var _path_line: Node3D = get_node_or_null("PathLine3D")
@export var capture_radius: float = 3.0


# Wander
const WANDER_INTERVAL := 2.5
const WANDER_RADIUS   := 22.0
var _wander_timer := 0.0
var _wander_point: Node3D = null

# Targeting / chase
enum AimMode { WANDER, CHASE }
var _aim_mode: int = AimMode.WANDER
var _aim_reason: String = "boot"
var _enemy: Character3D = null
var _seek_timer := 0.0
@export var lose_target_after: float = 2.0
var _lost_timer := 0.0

# Movement policy
@export var brute_when_wandering: bool = true
@export var brute_when_chasing: bool = false

var target: Node3D = null

func _dbg_id(node: Node) -> String:
	return "%s#%d" % [node.name, node.get_instance_id()]

func _ready() -> void:
	add_to_group("characters")
	if not is_in_group("npc"): add_to_group("npc")

	# Attach agent to the world nav map (only if agent exists)
	if agent != null:
		var world_map: RID = get_world_3d().navigation_map
		NavigationServer3D.agent_set_map(agent.get_rid(), world_map)
		await get_tree().process_frame
		var agent_map: RID = NavigationServer3D.agent_get_map(agent.get_rid())
		if not agent_map.is_valid():
			NavigationServer3D.agent_set_map(agent.get_rid(), world_map)
			agent_map = NavigationServer3D.agent_get_map(agent.get_rid())
		if debug_verbose:
			print("[Char]", name, " faction=", faction, " agent_map_valid=", agent_map.is_valid())

		# Agent tuning
		agent.avoidance_enabled = true
		agent.radius = 0.5
		agent.max_speed = move_speed
		agent.path_desired_distance = 0.25
		agent.target_desired_distance = 0.75

		# Signals
		agent.velocity_computed.connect(_on_agent_velocity_computed)
		agent.target_reached.connect(_on_agent_target_reached)
		agent.navigation_finished.connect(_on_agent_navigation_finished)
	else:
		if debug_verbose:
			print("[Char]", name, " has no NavigationAgent3D child; will use brute movement.")

	# Visual by faction (if mesh present)
	if mesh != null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = _faction_color(faction)
		mesh.material_override = mat

	# Optional: let a NavMgr attach extra stuff if present
	var nav_mgr := get_node_or_null("/root/NavMgr")
	if nav_mgr and nav_mgr.has_method("attach_agent") and agent != null:
		nav_mgr.call("attach_agent", agent)
	call_deferred("_snap_to_ground")


	# Start behavior
	_pick_target_or_wander()
	_update_agent_target()
	_init_runtime_health()

func setup_combat_profile_from_class(class_id: String) -> void:
	var path := "res://resources/combat/profiles/%s_default.tres" % class_id
	var exists := ResourceLoader.exists(path)
	if debug_verbose:
		print("[CharDBG] profile path=", path, " exists=", exists)

	var res: Resource = null
	if exists:
		res = ResourceLoader.load(path)

	var prof: CombatProfile = res as CombatProfile
	if prof != null:
		combat_profile = prof
		if debug_verbose:
			var entry_count := (prof.deck.entries.size() if prof.deck != null else 0)
			print("[CharDBG] profile OK class_id=", class_id, " deck_assigned=", (prof.deck != null), " entries=", entry_count)
	else:
		print("[Character3D] profile missing or wrong type at ", path, " -> using empty defaults")
		combat_profile = CombatProfile.new()

func _physics_process(delta: float) -> void:
	_tick_seek(delta)
	_tick_wander(delta)
	var next: Vector3 = _compute_next_point()
	_apply_movement(delta, next)
	_try_capture_building()

func _tick_seek(delta: float) -> void:
	# Enemy seeking & reacquire cadence
	_seek_timer -= delta

	if _enemy and is_instance_valid(_enemy):
		var d2 := global_transform.origin.distance_squared_to(_enemy.global_transform.origin)
		if d2 <= vision_radius * vision_radius:
			_lost_timer = 0.0
			if _seek_timer <= 0.0 and agent != null:
				_seek_timer = seek_interval_sec
				agent.set_target_position(_enemy.global_transform.origin)
		else:
			_lost_timer += delta
			if _lost_timer >= lose_target_after:
				if debug_verbose: print("[Char] ", name, " lost enemy")
				_enemy = null
				_pick_target_or_wander()
				_update_agent_target()
	else:
		if _seek_timer <= 0.0:
			_seek_timer = seek_interval_sec
			var found_target := _find_nearest_target()
			if found_target:
				_enemy = found_target as Character3D
				target = found_target
				_update_agent_target()

func _tick_wander(delta: float) -> void:
	# Periodic wander refresh or when path is finished
	_wander_timer += delta
	if _wander_timer >= WANDER_INTERVAL or _agent_is_nav_finished():
		_wander_timer = 0.0
		_set_random_wander_target()

func _compute_next_point() -> Vector3:
	# Choose the next usable corner/point from the path/agent
	var next := _agent_next_path_position()

	var path: PackedVector3Array = _agent_current_path()
	if path.size() >= 2:
		next = path[1]
	elif path.size() == 1:
		next = path[0]

	# Fallback to agent target if path looks degenerate
	if next == Vector3.ZERO or next.is_equal_approx(global_transform.origin):
		var tgt := _agent_target_position()
		if tgt != Vector3.INF:
			next = tgt
	return next

func _apply_movement(delta: float, next: Vector3) -> void:
	var use_brute := (_enemy == null and brute_when_wandering) or (_enemy != null and brute_when_chasing)

	if use_brute or agent == null:
		var d_vec := next - global_transform.origin
		d_vec.y = 0.0
		var d := d_vec.length()
		if d > 0.01:
			var step := move_speed * delta
			global_transform.origin += d_vec.normalized() * step
		if debug_verbose:
			print("[Char]", name, " BRUTE next=", next, " chasing=", _enemy != null)
	else:
		# Physics / agent-driven move
		var dir := next - global_transform.origin
		dir.y = 0.0
		var d := dir.length()
		var desired := Vector3.ZERO
		if d > 0.01:
			desired = (dir / d) * move_speed

		agent.set_velocity(desired)
		velocity.x = desired.x
		velocity.z = desired.z
		move_and_slide()

		if debug_verbose:
			var pc := _agent_current_path().size()
			print("[Char]", name, " PHYS vel=", desired, " d=", d, " path_count=", pc)

func _try_capture_building() -> void:
	if target and is_instance_valid(target) and _is_hostile_building(target):
		var dist2 := global_transform.origin.distance_squared_to(target.global_transform.origin)
		if dist2 <= capture_radius * capture_radius:
			var dist := sqrt(dist2)
			var tf = target.get("faction")  # safe property read
			if debug_verbose:
				print("[Char] capture-check actor=", _dbg_id(self),
					" target=", _dbg_id(target), " dist=", dist, " <= cap_r=", capture_radius,
					" targetFaction=", (str(tf) if tf != null else "NA"),
					" actorFaction=", faction)

			# Ask AbstractWorld to remove both 3D + 2D for this building
			var abs := _get_abstract_world()
			if abs != null:
				if debug_verbose:
					print("[Char] capture-WORLD-REMOVE actor=", _dbg_id(self), " target=", _dbg_id(target))
				abs.remove_building_by_node(target, "captured_by:" + _dbg_id(self))
			else:
				# Fallback (3D only) so we can see when world lookup fails
				print("[Char][WARN] AbstractWorld not found; 3D-only queue_free for ", _dbg_id(target))
				target.queue_free()

			# Clear state and reacquire
			target = null
			_enemy = null
			_pick_target_or_wander()
			_update_agent_target()

func _get_abstract_world() -> AbstractWorld:
	# Walk up to the GameLevel (it owns `_abs : AbstractWorld`) and grab it.
	var n: Node = self
	while n != null:
		var candidate = n.get("_abs")
		if candidate != null and candidate is AbstractWorld:
			return candidate
		n = n.get_parent()
	return null

#
#func _physics_process(delta: float) -> void:
	## --- Enemy seeking tick ---
	#_seek_timer -= delta
#
	## Keep targets updated / reacquire
	#if _enemy and is_instance_valid(_enemy):
		#var d2 := global_transform.origin.distance_squared_to(_enemy.global_transform.origin)
		#if d2 <= vision_radius * vision_radius:
			#_lost_timer = 0.0
			#if _seek_timer <= 0.0 and agent != null:
				#_seek_timer = seek_interval_sec
				#agent.set_target_position(_enemy.global_transform.origin)
		#else:
			#_lost_timer += delta
			#if _lost_timer >= lose_target_after:
				#if debug_verbose: print("[Char] ", name, " lost enemy")
				#_enemy = null
				#_pick_target_or_wander()
				#_update_agent_target()
	#else:
		#if _seek_timer <= 0.0:
			#_seek_timer = seek_interval_sec
			#var found_target := _find_nearest_target()
			#if found_target:
				#_enemy = (found_target if found_target is Character3D else null)
				#target = found_target
				#_update_agent_target()
#
	## Periodic wander change (or if done)
	#_wander_timer += delta
	#if _wander_timer >= WANDER_INTERVAL or _agent_is_nav_finished():
		#_wander_timer = 0.0
		#_set_random_wander_target()
#
	## --- Choose a usable "next" corner ---
	#var next: Vector3 = _agent_next_path_position()
#
	## Prefer skipping the first vertex (which is usually our current position).
	#var path: PackedVector3Array = _agent_current_path()
	#if path.size() >= 2:
		#next = path[1]
	#elif path.size() == 1:
		#next = path[0]
#
	## Fallback to target if needed
	#if next == Vector3.ZERO or next == global_transform.origin or next.is_equal_approx(global_transform.origin):
		#var tgt := _agent_target_position()
		#if tgt != Vector3.INF:
			#next = tgt
#
	## --- Compute movement towards "next" ---
	#var use_brute := (_enemy == null and brute_when_wandering) or (_enemy != null and brute_when_chasing)
#
	#if use_brute or agent == null:
		#var d_vec := next - global_transform.origin
		#d_vec.y = 0.0
		#var d := d_vec.length()
		#if d > 0.01:
			#var step := move_speed * delta
			#global_transform.origin += d_vec.normalized() * step
		#if debug_verbose:
			#print("[Char]", name, " BRUTE next=", next, " chasing=", _enemy != null)
	#else:
		## Physics movement (agent-driven)
		#var dir := next - global_transform.origin
		#dir.y = 0.0
		#var d := dir.length()
		#var desired := Vector3.ZERO
		#if d > 0.01:
			#desired = (dir / d) * move_speed
#
		#agent.set_velocity(desired)
		#velocity.x = desired.x
		#velocity.z = desired.z
		#move_and_slide()
#
		#if debug_verbose:
			#var pc := _agent_current_path().size()
			#print("[Char]", name, " PHYS vel=", desired, " d=", d, " path_count=", pc)
		#if target and is_instance_valid(target):
			#if _is_hostile_building(target):
				#var dist2_to_building := global_transform.origin.distance_squared_to(target.global_transform.origin)
				#if dist2_to_building <= capture_radius * capture_radius:
					#if debug_verbose:
						#print("[Char]", name, " captured & removed building: ", target.name)
#
					#var dist_to_building := sqrt(dist2_to_building)
					#var tf = target.get("faction")  # safe even if property doesn't exist on the node
#
					#print("[Char] capture-check actor=", _dbg_id(self),
						#" target=", _dbg_id(target), " dist=", dist_to_building, " <= cap_r=", capture_radius,
						#" targetFaction=", (str(tf) if tf != null else "NA"),
						#" actorFaction=", faction)
#
					#print("[Char] capture-REMOVE actor=", _dbg_id(self), " removing=", _dbg_id(target))
#
					#target.queue_free()
					#target = null
					#_enemy = null
					#_pick_target_or_wander()
					#_update_agent_target()


func _pick_target_or_wander() -> void:
	if debug_verbose: print("[Char] pick-begin actor=", _dbg_id(self))
	var found: Node3D = _find_nearest_target()
	if debug_verbose:
		print("[Char] pick-found actor=", _dbg_id(self), " found=", (found and _dbg_id(found) or "null"),
		" isChar=", (found is Character3D),
		" isBldg=", (found and found.is_in_group("Buildings")))
	if found:
		# Only set _enemy if the found target is a Character3D (so combat code stays type-safe)
		if found is Character3D:
			_enemy = found
		else:
			_enemy = null
		target = found
		_aim_mode = AimMode.CHASE
		_aim_reason = "acquired_target"
	else:
		_enemy = null
		target = null
		_make_or_move_wander_point()
		_aim_mode = AimMode.WANDER
		_aim_reason = "no_target_found"
	
	_update_agent_target()
	_debug_refresh(_aim_reason)


func _set_random_wander_target() -> void:
	_make_or_move_wander_point()
	_update_agent_target()

func _make_or_move_wander_point() -> void:
	var map := get_world_3d().navigation_map
	var base := global_transform.origin
	base.y = 0.41
	if _wander_point == null or not is_instance_valid(_wander_point):
		_wander_point = Node3D.new()
		_wander_point.name = "WanderPoint"
		if get_tree().current_scene != null:
			get_tree().current_scene.add_child(_wander_point)
	for i in range(8):
		var angle := randf() * TAU
		var r := randf_range(WANDER_RADIUS * 0.5, WANDER_RADIUS)
		var guess := base + Vector3(cos(angle) * r, 0.0, sin(angle) * r)
		var on_nav := NavigationServer3D.map_get_closest_point(map, guess)
		if on_nav != Vector3.INF:
			on_nav.y = 0.41
			# NEW: don't pick targets within the "too close" zone
			if on_nav.distance_to(global_transform.origin) < min_set_target_distance:
				continue
			_wander_point.global_transform.origin = on_nav
			target = _wander_point
			if debug_verbose:
				print("[Char]", name, " wander target=", on_nav)
			return

#func _find_nearest_enemy() -> Character3D:
	#var me: Vector3 = global_transform.origin
	#var best: Character3D = null
	#var best_d2 := INF
	#var seen := 0
	#for n in get_tree().get_nodes_in_group("characters"):
		#if n == self:
			#continue
		#if not (n is Character3D):
			#continue
		#var other := n as Character3D
		#if other.faction == faction:
			#continue
		#var d2 := me.distance_squared_to(other.global_transform.origin)
		#if ignore_radius_for_acquire or d2 <= vision_radius * vision_radius:
			#seen += 1
			#if d2 < best_d2:
				#best_d2 = d2
				#best = other
	#if debug_verbose:
		#print("[Char]", name, " scan: seen_enemies=", seen, " chosen=", (best.name if best else "null"))
	#return best

func _find_nearest_target() -> Node3D:
	if debug_verbose: print("[Char] scan-begin actor=", _dbg_id(self), " faction=", faction, " vision_r=", vision_radius)
	var me: Vector3 = global_transform.origin
	var best: Node3D = null
	var best_d2 := INF
	var seen := 0

	# Collect candidates: enemy characters + enemy buildings
	var pools := [
		get_tree().get_nodes_in_group("characters"),
		get_tree().get_nodes_in_group("Buildings")
	]

	for arr in pools:
		for n in arr:
			
			if n == self:
				continue
			if not (n is Node3D):
				continue
			var node := n as Node3D
			if debug_verbose:
				print("[Char] scan-candidate actor=", _dbg_id(self), " cand=", _dbg_id(node),
	  			" groups=[chars=", node.is_in_group("characters"), ", bldg=", node.is_in_group("Buildings"), "]",
	  			" hostile=", _is_hostile(node))
			if not _is_hostile(node):
				continue

			var d2 := me.distance_squared_to(node.global_transform.origin)
			if ignore_radius_for_acquire or d2 <= vision_radius * vision_radius:
				seen += 1
				if d2 < best_d2:
					best_d2 = d2
					best = node
					

	if debug_verbose:
		print("[Char]", name, " scan: seen_targets=", seen, " chosen=", (best.name if best else "null"))
	return best

func _is_hostile(node: Node) -> bool:
	# Characters
	if node is Character3D:
		return (node as Character3D).faction != faction

	# Buildings (Settlement3D / City3D) expose `faction` and are in "Buildings"
	if node.is_in_group("Buildings"):
		# Be defensive: many Node3D don’t have "faction"
		if "faction" in node:
			return node.faction != faction
		# If no faction property, treat as neutral / not hostile
		return false

	return false

func _is_hostile_building(node: Node) -> bool:
	return node.is_in_group("Buildings") and _is_hostile(node)

func _update_agent_target() -> void:
	if debug_verbose:
		print("[Char] start nav-set actor=", _dbg_id(self),
			" target=", (target and _dbg_id(target) or "null"),
			" agent.valid=", (agent != null),
			" agent.nav_ok=", (agent and agent.is_navigation_finished() == false))

	if target and is_instance_valid(target) and agent != null:
		var pos := target.global_transform.origin
		pos.y = 0.41
		_safe_set_agent_target(pos)

		if debug_verbose:
			var map: RID = get_world_3d().navigation_map
			var me_on: Vector3  = NavigationServer3D.map_get_closest_point(map, global_transform.origin)
			var tgt_on: Vector3 = NavigationServer3D.map_get_closest_point(map, pos)
			var me_ok: bool  = me_on != Vector3.INF and me_on.distance_to(global_transform.origin) < 1.0
			var tgt_ok: bool = tgt_on != Vector3.INF and tgt_on.distance_to(pos) < 1.0
			print("[Char]", name, " set_target pos=", pos, " me_on_nav=", me_ok, " tgt_on_nav=", tgt_ok)

	if debug_verbose:
		print("[Char] end nav-set actor=", _dbg_id(self),
			" target=", (target and _dbg_id(target) or "null"),
			" agent.valid=", (agent != null),
			" agent.nav_ok=", (agent and agent.is_navigation_finished() == false))

# --- Signals ---
func _on_agent_velocity_computed(safe_velocity: Vector3) -> void:
	if agent == null:
		return
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z

func _on_agent_target_reached() -> void:
	if _handling_nav_signal:
		return
	_handling_nav_signal = true

	# Defer a tick to avoid synchronous re-entry in the same frame.
	var _t := get_tree().create_timer(min_retarget_delay)
	await _t.timeout

	if _aim_mode == AimMode.CHASE and _enemy and is_instance_valid(_enemy):
		_safe_set_agent_target(_enemy.global_transform.origin)
	else:
		_set_random_wander_target()

	_handling_nav_signal = false


func _on_agent_navigation_finished() -> void:
	if _handling_nav_signal:
		return
	_handling_nav_signal = true
	call_deferred("_nav_finished_deferred")

func _nav_finished_deferred() -> void:
	if _aim_mode == AimMode.CHASE and _enemy and is_instance_valid(_enemy):
		_safe_set_agent_target(_enemy.global_transform.origin)
	else:
		_set_random_wander_target()
	_handling_nav_signal = false

# --- Debug helpers ---
func _debug_refresh(reason: String = "") -> void:
	if not debug_verbose:
		return
	var tgt := _agent_target_position()
	var mode_str := "CHASE" if _aim_mode == AimMode.CHASE else "WANDER"
	var who := "null"
	if _enemy and is_instance_valid(_enemy):
		who = _enemy.name
	elif target and is_instance_valid(target):
		who = target.name

	var d := -1.0
	if tgt != Vector3.INF:
		d = global_transform.origin.distance_to(tgt)

	var path := _agent_current_path()

	if _label3d:
		var finished_str := "false"
		if agent != null and agent.has_method("is_navigation_finished"):
			finished_str = str(agent.is_navigation_finished())
		_label3d.text = "%s\nreason=%s\ntgt=%s\ndist=%.1f\npath_pts=%d\nnav_finished=%s" % [
			mode_str, reason, str(tgt), d, path.size(), finished_str
		]

	if debug_draw_path and _path_line and _path_line.has_method("clear_points"):
		_path_line.visible = true
		_path_line.clear_points()
		for p in path:
			_path_line.add_point(p + Vector3.UP * 0.05)

	print("[Char]", name, " MODE=", mode_str, " reason=", reason, " tgt=", tgt, " who=", who, " dist=%.2f" % d, " path_pts=", path.size())

# --- Agent helpers (null-safe) ---
func _agent_is_nav_finished() -> bool:
	if agent == null:
		return false
	return agent.is_navigation_finished()

func _agent_next_path_position() -> Vector3:
	if agent == null:
		return global_transform.origin
	return agent.get_next_path_position()

func _agent_current_path() -> PackedVector3Array:
	if agent == null:
		return PackedVector3Array()
	return agent.get_current_navigation_path()

func _agent_target_position() -> Vector3:
	if agent == null:
		return Vector3.INF
	return agent.get_target_position()

# --- Utils ---
func _faction_color(f: int) -> Color:
	match f:
		0: return Color(0.9, 0.2, 0.2) # red
		1: return Color(0.2, 0.6, 0.9) # blue
		2: return Color(0.3, 0.9, 0.4) # green
		3: return Color(0.9, 0.8, 0.2) # yellow
		_: return Color(0.8, 0.8, 0.8)

func set_encounter_locked(locked: bool) -> void:
	_encounter_locked = locked
	if locked:
		if agent != null:
			agent.set_target_position(global_position)
		velocity = Vector3.ZERO
	set_physics_process(not locked)

func _init_runtime_health() -> void:
	var base := 30
	if combat_profile != null:
		base = int(combat_profile.base_health)
	if runtime_health <= 0:
		runtime_health = base
	if debug_verbose:
		print("[Char]", name, " health_init=", runtime_health, " base=", base, " combat profile", combat_profile)

func apply_damage(amount: int, source: Node3D = null) -> void:
	if _is_dead:
		return
	amount = max(amount, 0)
	var before := runtime_health
	runtime_health = max(0, runtime_health - amount)
	if debug_verbose:
		print("[Char]", name, " took ", amount, "hp (", before, "->", runtime_health, ") from ", (source.name if source else "unknown"))
	if runtime_health <= 0:
		on_death(source)

func heal(amount: int) -> void:
	if _is_dead:
		return
	amount = max(amount, 0)
	var base := (int(combat_profile.base_health) if combat_profile != null else 30)
	runtime_health = clamp(runtime_health + amount, 0, base)

func on_death(killer: Node3D = null) -> void:
	if _is_dead:
		return
	_is_dead = true
	if debug_verbose:
		print("[Character3D] ", name, " died; killer=", (killer.name if killer else "unknown"))
	set_encounter_locked(true)
	remove_from_group("characters")
	call_deferred("queue_free")

func _snap_to_ground() -> void:
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3.UP * (ground_max_check * 0.5)
	var to   := global_position - Vector3.UP * ground_max_check

	var qp := PhysicsRayQueryParameters3D.create(from, to)
	qp.collision_mask = ground_mask
	var hit := space.intersect_ray(qp)

	if hit.has("position"):
		global_position = hit.position + Vector3.UP * hover_height

func _safe_set_agent_target(pos: Vector3) -> void:
	if agent == null:
		return
	# Avoid instant target_reached re-emission
	if global_transform.origin.distance_to(pos) < min_set_target_distance:
		return
	agent.set_target_position(pos)
