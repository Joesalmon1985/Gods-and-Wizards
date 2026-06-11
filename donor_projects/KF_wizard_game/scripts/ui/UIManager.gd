extends Node
@export var debug_verbose: bool = false

var _active_encounter: CardCombatEncounter = null
var _you_name_cached: String = "You"
var _enemy_name_cached: String = "Enemy"

var _layer: CanvasLayer
var _ui: CombatEncounterUI
var _pending_pick: Callable = Callable()   # reused for RPS or Cards
var _active_session_id: String = ""

func set_anticipation_text(text: String) -> void:
	if _ui and is_instance_valid(_ui):
		_ui.set_anticipation_text(text)

func clear_anticipation() -> void:
	if _ui and is_instance_valid(_ui):
		_ui.clear_anticipation()

func _ready() -> void:
	add_to_group("ui_manager")
	print("[UIManager] ready; paused=", get_tree().paused)


# ---- input lock for the local player only (no global pause) ----------------
func _lock_local_player(lock: bool) -> void:
	var player: Node = null
	var gp := get_tree().get_nodes_in_group("player")
	if gp.size() > 0:
		player = gp[0]
	else:
		player = get_tree().root.get_node_or_null("MainGame/GameLevel/PlayerCharacter")
		if player == null:
			player = get_tree().root.get_node_or_null("PlayerCharacter")

	if player and player.has_method("set_input_enabled"):
		player.call("set_input_enabled", not lock)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if lock else Input.MOUSE_MODE_CAPTURED)
	print("[UIManager] _lock_local_player lock=", lock, " mouse_mode=", Input.get_mouse_mode())

# ---- canvas & panel helpers -------------------------------------------------
func _ensure_layer() -> void:
	if _layer and is_instance_valid(_layer):
		return
	_layer = CanvasLayer.new()
	_layer.name = "UILayer"
	_layer.layer = 100
	add_child(_layer)
	print("[UIManager] Created CanvasLayer 'UILayer' (layer=100). path=", _layer.get_path())


# ---- API: RPS ---------------------------------------------------------------
func begin_rps_choice(on_pick: Callable) -> void:
	_ensure_ui()
	_pending_pick = on_pick
	print("[UIManager] begin_rps_choice: pending_pick.is_valid()=", _pending_pick.is_valid())
	_lock_local_player(true)
	_ui.show_prompt(true)
	print("[UIManager] Showing RPS prompt to player.")

# ---- API: Cards -------------------------------------------------------------
func begin_card_choice(hand: Array, anticipated: bool, on_pick: Callable, anticipated_text: String = "") -> void:
	_ensure_ui()
	_pending_pick = on_pick
	print("[UIManager] begin_card_choice: hand.size=", hand.size(),
		  " anticipated=", anticipated, " text='", anticipated_text, "'")
	_lock_local_player(true)
	if _ui != null and _ui.has_method("show_hand"):
		_ui.show_hand(hand, anticipated, anticipated_text)
	else:
		print("[UIManager] ERROR: CombatEncounterUI missing or no show_hand(hand,bool,String)")


# ---- finish / cleanup -------------------------------------------------------
func end_rps_ui() -> void:
	end_card_ui() # same cleanup

func end_card_ui() -> void:
	if _ui and is_instance_valid(_ui):
		_ui.queue_free()
	_ui = null
	_pending_pick = Callable()
	_lock_local_player(false)

# ---- status + log -----------------------------------------------------------
func update_rps_status(ctx: Dictionary) -> void:
	if debug_verbose:
		print("[UIManager] update_rps_status: ctx=%s" % [JSON.stringify(ctx)])

	# Ensure UI exists early so first ctx doesn't get dropped
	if _ui == null or not is_instance_valid(_ui):
		if debug_verbose:
			print("[UIManager][INFO] _ui missing → creating now in update_rps_status")
		_ensure_ui()
		# If we know the active encounter, wire it now
		if _active_encounter != null:
			_active_encounter.set_ui(_ui)

		# Prime with something readable *right now*
		_ui.set_status_text("Ready")
		_ui.set_anticipation_text("")
		_ui.clear_log()
		# If sides not shown yet, paint placeholders using cached names
		_ui.show_sides(_you_name_cached, 0, 30, _enemy_name_cached, 0, 30)

	# From here, call the UI's dictionary-based status updater (we'll fix it next)
	if "attacker_name" in ctx and "defender_name" in ctx:
		_ui.set_status(ctx)
	else:
		# keep Ready, nothing else to map yet
		pass

func push_log(msg: String) -> void:
	print("[UIManager] push_log:", msg)
	if _ui and is_instance_valid(_ui):
		_ui.append_log(msg)
	else:
		print("[UIManager][WARN] push_log called but _ui is missing.")

# ---- signal handlers --------------------------------------------------------
func _on_rps_chosen(move: int) -> void:
	print("[UIManager] _on_rps_chosen move=", move)
	if _ui and is_instance_valid(_ui):
		_ui.show_prompt(false)
	_lock_local_player(false)
	if _pending_pick.is_valid():
		var cb := _pending_pick
		_pending_pick = Callable()
		cb.call(move)

func _on_card_chosen(ix: int) -> void:
	print("[UIManager] _on_card_chosen ix=", ix)
	# Leave the card panel up; encounter will call begin_card_choice again for next prompt.
	_lock_local_player(false)
	if _pending_pick.is_valid():
		var cb := _pending_pick
		_pending_pick = Callable()
		cb.call(ix)

func close_encounter_ui(session_id: String = "") -> void:
	if session_id != "" and _active_session_id != "" and session_id != _active_session_id:
		print("[UIManager] close_encounter_ui: sid mismatch -> ignoring (got=", session_id, " want=", _active_session_id, ")")
		return

	if _ui and is_instance_valid(_ui):
		print("[UIManager] close_encounter_ui: removing CombatEncounterUI")
		_ui.queue_free()
		_ui = null

	# unlock player & restore mouse capture
	_lock_local_player(false)

	# If you want to fully tear down the layer when empty (optional, harmless if left as-is):
	if _layer and is_instance_valid(_layer) and _layer.get_child_count() == 0:
		_layer.queue_free()
		_layer = null
		print("[UIManager] UILayer removed")
		
func _ensure_ui() -> void:
	if debug_verbose:
		print("[UIManager] _ensure_ui called (layer=%s ui=%s)" % [_layer, _ui])

	if _layer == null or not is_instance_valid(_layer):
		_layer = CanvasLayer.new()
		_layer.name = "UILayer"
		add_child(_layer)
		if debug_verbose:
			print("[UIManager] Created CanvasLayer '%s' at %s" % [_layer.name, _layer.get_path()])

	if _ui == null or not is_instance_valid(_ui):
		_ui = CombatEncounterUI.new()
		_ui.name = "CombatEncounterUI"
		_layer.add_child(_ui)
		if debug_verbose:
			print("[UIManager] Added CombatEncounterUI at:%s (tree.paused=%s)" % [_ui.get_path(), get_tree().paused])

		# One-time signal hookups
		if not _ui.rps_chosen.is_connected(_on_rps_chosen):
			_ui.rps_chosen.connect(_on_rps_chosen)
			if debug_verbose: print("[UIManager] Connected rps_chosen")
		if not _ui.card_chosen.is_connected(_on_card_chosen):
			_ui.card_chosen.connect(_on_card_chosen)
			if debug_verbose: print("[UIManager] Connected card_chosen")


func attach_encounter_ui(encounter: CardCombatEncounter, you: Node, enemy: Node) -> void:
	if debug_verbose:
		print("[UIManager] attach_encounter_ui encounter=%s you=%s enemy=%s" % [encounter, you, enemy])

	_active_encounter = encounter
	_ensure_ui()
	encounter.set_ui(_ui)
	encounter.set_sides(you, enemy)

	# Cache display names for mapping later (in case ctx arrives before choices)
	_you_name_cached = _pretty_name(you)
	_enemy_name_cached = _pretty_name(enemy)

	# Best-effort HP read for initial paint
	var y_hp := _read_hp_pair(you)  # [hp,max]
	var e_hp := _read_hp_pair(enemy)

	# Prime the panel immediately so it never shows blank
	_ui.set_status_text("Ready")
	_ui.set_anticipation_text("")
	_ui.clear_log()
	_ui.show_sides(_you_name_cached, y_hp[0], y_hp[1], _enemy_name_cached, e_hp[0], e_hp[1])

func _pretty_name(n: Node) -> String:
	if n == null: return "Unknown"
	if n.has_method("get") and n.get("display_name") != null:
		return str(n.get("display_name"))
	return str(n.name)

func _read_hp_pair(n: Node) -> Array:
	var hp := 0
	var max_hp := 0
	if n != null and n.has_method("get"):
		if n.get("runtime_health") != null: hp = int(n.get("runtime_health"))
		if n.get("max_health") != null: max_hp = int(n.get("max_health"))
		elif n.get("combat_profile") != null:
			var prof = n.get("combat_profile")
			if prof != null and prof.has_method("get") and prof.get("max_health") != null:
				max_hp = int(prof.get("max_health"))
	if max_hp <= 0: max_hp = max(hp, 30)
	return [hp, max_hp]
