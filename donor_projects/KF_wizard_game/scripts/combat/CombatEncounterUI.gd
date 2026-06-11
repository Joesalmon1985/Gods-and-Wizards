extends Control
class_name CombatEncounterUI
@export var debug_verbose: bool = false

signal rps_chosen(move: int)
signal card_chosen(ix: int)

# --- UI nodes ---
var _status_label: Label
var _atk_label: Label
var _def_label: Label
var _anticipation_label: Label
var _log: RichTextLabel
var _hand_box: HBoxContainer
var _prompt_box: HBoxContainer
var _card_btns: Array[Button] = []

# --- state ---
var _current_hand: Array = []
var _anticipated: bool = false

# --- Fixed "You / Enemy" display support -------------------------------------

var _you_name: String = "You"
var _enemy_name: String = "Enemy"

func set_anticipation_text(text: String) -> void:
	# Show "Anticipation: X" above the move buttons
	if debug_verbose: print("[CombatEncounterUI] setting anticipation", text)
	if is_instance_valid(_anticipation_label):
		_anticipation_label.text = "Anticipation: %s" % str(text)
		_anticipation_label.visible = text != ""

func clear_anticipation() -> void:
	# Hide and clear the anticipation line
	if is_instance_valid(_anticipation_label):
		_anticipation_label.text = ""
		_anticipation_label.visible = false


func show_sides(you_name: String, you_hp: int, you_max: int, enemy_name: String, enemy_hp: int, enemy_max: int) -> void:
	if debug_verbose:
		print("[CombatEncounterUI] show_sides you=%s %d/%d enemy=%s %d/%d" %
			[you_name, you_hp, you_max, enemy_name, enemy_hp, enemy_max])
	# Called once by the encounter when combat opens (or if the opponent changes).
	_you_name = you_name
	_enemy_name = enemy_name
	update_health(you_hp, you_max, enemy_hp, enemy_max)

func update_health(you_hp: int, you_max: int, enemy_hp: int, enemy_max: int) -> void:
	if debug_verbose:
		print("[CombatEncounterUI] update_health you=%d/%d enemy=%d/%d" %
			[you_hp, you_max, enemy_hp, enemy_max])
	# Keep these two labels permanently mapped: left = You, right = Enemy.
	if is_instance_valid(_atk_label):
		_atk_label.text = "%s: %d/%d" % [_you_name, you_hp, you_max]
	if is_instance_valid(_def_label):
		_def_label.text = "%s: %d/%d" % [_enemy_name, enemy_hp, enemy_max]

func set_round_roles(attacker_is_you: bool) -> void:
	if debug_verbose:
		print("[CombatEncounterUI] set_round_roles attacker_is_you=%s" % [attacker_is_you])
	if is_instance_valid(_status_label):
		_status_label.text = ("This round: You are Attacker"
			if attacker_is_you
			else "This round: Enemy is Attacker")

func _ready() -> void:
	name = "CombatEncounterUI"
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	_build_ui()
	_setup_actions()
	if debug_verbose: print("[CombatEncounterUI] _ready at path=", get_path())
	if is_instance_valid(_status_label):
		_status_label.text = "Ready"
	if is_instance_valid(_atk_label):
		_atk_label.text = "You: -/-"
	if is_instance_valid(_def_label):
		_def_label.text = "Enemy: -/-"
	if is_instance_valid(_anticipation_label):
		_anticipation_label.text = ""
	if is_instance_valid(_log):
		_log.clear()

func _build_ui() -> void:
	# Panel
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(520, 240)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.name = "Root"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	# Status area
	_status_label = Label.new()
	_status_label.text = "Ready"
	root.add_child(_status_label)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 16)
	root.add_child(hp_row)

	_atk_label = Label.new()
	_atk_label.text = "Attacker: -"
	hp_row.add_child(_atk_label)

	_def_label = Label.new()
	_def_label.text = "Defender: -"
	hp_row.add_child(_def_label)

	_anticipation_label = Label.new()
	_anticipation_label.text = ""
	_anticipation_label.visible = false
	root.add_child(_anticipation_label)

	# Hand (card) row
	_hand_box = HBoxContainer.new()
	_hand_box.add_theme_constant_override("separation", 8)
	root.add_child(_hand_box)

	for i in 3:
		var b := Button.new()
		b.text = "-"
		b.custom_minimum_size = Vector2(140, 40)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_on_card_btn.bind(i))
		_card_btns.append(b)
		_hand_box.add_child(b)

	# RPS prompt (kept for compatibility; hidden by default)
	_prompt_box = HBoxContainer.new()
	_prompt_box.visible = false
	_prompt_box.add_theme_constant_override("separation", 8)
	root.add_child(_prompt_box)


	# Log
	_log = RichTextLabel.new()
	_log.fit_content = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_log)

func _setup_actions() -> void:
	# Card hotkeys: R / T / Y
	_add_key_action_once("card_slot_0", KEY_R)
	_add_key_action_once("card_slot_1", KEY_T)
	_add_key_action_once("card_slot_2", KEY_Y)
	# RPS prompt hotkeys: 1 / 2 / 3 (avoid clashing with R/T/Y)
	_add_key_action_once("rps_rock", KEY_1)
	_add_key_action_once("rps_paper", KEY_2)
	_add_key_action_once("rps_scissors", KEY_3)

func _add_key_action_once(action: String, keycode: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.keycode = keycode
		InputMap.action_add_event(action, ev)
		print("[CombatEncounterUI] Added action:", action, " key=", keycode)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var e := event as InputEventKey
	if not e.pressed or e.echo:
		return


	# Card hand active?
	if _hand_box.visible:
		if Input.is_action_just_pressed("card_slot_0"):
			_emit_card(0); return
		if Input.is_action_just_pressed("card_slot_1"):
			_emit_card(1); return
		if Input.is_action_just_pressed("card_slot_2"):
			_emit_card(2); return

# --- Public API expected by UIManager ---------------------------------------

func show_prompt(show: bool) -> void:
	_prompt_box.visible = show
	_hand_box.visible = not show
	_anticipation_label.visible = false
	
func show_hand(hand: Array, anticipated: bool, anticipated_text: String = "") -> void:
	if debug_verbose: print("[CombatEncounterUI] show_hand size=", hand.size(),
		  " anticipated=", anticipated, " text='", anticipated_text, "'")
	if debug_verbose:
		print("[CardCombatEncounterUI] NEW DEBUG anticipated = ", anticipated, anticipated_text )
	_current_hand = hand.duplicate()
	_anticipated = anticipated

	if is_instance_valid(_prompt_box):
		_prompt_box.visible = false
	if is_instance_valid(_hand_box):
		_hand_box.visible = true
	if is_instance_valid(_anticipation_label):
		_anticipation_label.visible = anticipated
		_anticipation_label.text = "Anticipating attack!" + anticipated_text if anticipated else ""

	# Populate buttons with card names and slot key hints (R/T/Y)
	for i in _card_btns.size():
		var b := _card_btns[i]
		if i < hand.size() and hand[i] != null:
			var card = hand[i]
			var base_label := ""
			# Try display_name, then name, then fallback to str(card)
			if card.has_method("get") and card.get("display_name") != null:
				base_label = str(card.get("display_name"))
			elif card.has_method("get") and card.get("name") != null:
				base_label = str(card.get("name"))
			elif "name" in card:
				base_label = str(card.name)
			else:
				base_label = str(card)

			var key_hint := _first_key_for_action(_slot_action_name(i))
			if key_hint == "":
				key_hint = _slot_fallback_key(i)

			b.text = _format_with_key_hint(key_hint, base_label)
			b.disabled = false
			b.visible = true
			b.focus_mode = Control.FOCUS_ALL
		else:
			b.text = "-"
			b.disabled = true
			b.visible = (i < 3)

	if debug_verbose:
		var labels := []
		for btn in _card_btns:
			labels.append(btn.text)
		print("[CombatEncounterUI] show_hand size=%d anticipated=%s labels=%s" % [hand.size(), anticipated, labels])

		
func set_status(ctx: Dictionary) -> void:
	# ctx keys we care about:
	# "session_id", "attacker_name", "attacker_hp", "attacker_max", "defender_name", "defender_hp", "defender_max"
	if debug_verbose:
		print("[CombatEncounterUI] set_status ctx keys=%s" % [ctx.keys()])

	# If we don't even have names yet, don't flip to A/D — keep primed placeholders
	if not ctx.has("attacker_name") or not ctx.has("defender_name"):
		if debug_verbose:
			print("[CombatEncounterUI][INFO] set_status without names; keeping current labels")
		return

	var a_name := str(ctx.get("attacker_name"))
	var d_name := str(ctx.get("defender_name"))
	var a_hp := int(ctx.get("attacker_hp", 0))
	var a_max := int(ctx.get("attacker_max", 30))
	var d_hp := int(ctx.get("defender_hp", 0))
	var d_max := int(ctx.get("defender_max", 30))

	# --- Map to fixed sides ---
	# Left label must always be You, right label must always be Enemy.
	var you_hp := 0
	var you_max := 30
	var enemy_hp := 0
	var enemy_max := 30

	# You matches the name we locked in show_sides()
	# If the attacker is You, pull numbers from attacker; else from defender.
	if a_name == _you_name:
		you_hp = a_hp; you_max = a_max
		enemy_hp = d_hp; enemy_max = d_max
	elif d_name == _you_name:
		you_hp = d_hp; you_max = d_max
		enemy_hp = a_hp; enemy_max = a_max
	else:
		# Fallback: names didn't match (e.g., NPC vs NPC); keep A/D mapping but still label You/Enemy
		you_hp = a_hp; you_max = a_max
		enemy_hp = d_hp; enemy_max = d_max

	update_health(you_hp, you_max, enemy_hp, enemy_max)

	# Optional: status line can say who attacks *this* round, without flipping sides.
	var attacker_is_you := (a_name == _you_name)
	set_round_roles(attacker_is_you)

func append_log(msg: String) -> void:
	_log.append_text(msg + "\n")

# --- helpers -----------------------------------------------------------------

func _on_card_btn(ix: int) -> void:
	_emit_card(ix)

func _emit_card(ix: int) -> void:
	if ix >= 0 and ix < _current_hand.size():
		print("[CombatEncounterUI] CARD pressed index=", ix)
		card_chosen.emit(ix)

func _on_rps_btn(move: int) -> void:
	_emit_rps(move)

func _emit_rps(move: int) -> void:
	print("[CombatEncounterUI] RPS pressed move=", move)
	rps_chosen.emit(move)

# --- Panel priming helpers ----------------------------------------------------
# --- Panel priming helpers (string-based) ------------------------------------

func set_status_text(text: String) -> void:
	if debug_verbose:
		print("[CombatEncounterUI] set_status_text '%s'" % text)
	if is_instance_valid(_status_label):
		_status_label.text = text

func set_prompt_text(text: String) -> void:
	# If you already have a prompt label, wire it here; otherwise reuse status
	if has_node("PromptLabel"):
		var lbl := get_node("PromptLabel") as Label
		if is_instance_valid(lbl):
			lbl.text = text
	elif is_instance_valid(_status_label):
		_status_label.text = "%s\n%s" % [_status_label.text, text]


func clear_log() -> void:
	if is_instance_valid(_log):
		_log.clear()

# --- Keyboard hint helpers ----------------------------------------------------

# Returns "R", "T", "Y", "1", etc., for the *first* key bound to an action.
func _first_key_for_action(action_name: String) -> String:
	if not InputMap.has_action(action_name):
		return ""
	var events := InputMap.action_get_events(action_name)
	for e in events:
		var kev := e as InputEventKey
		if kev != null:
			# Prefer physical keycode so letters are stable across layouts.
			var s := OS.get_keycode_string(kev.physical_keycode)
			if s != "":
				return s
			# Fallback to textual representation.
			return kev.as_text()
	return ""

func _slot_action_name(ix: int) -> String:
	# We already use actions like card_slot_0/1/2 → mapped to R/T/Y in your project.
	return "card_slot_%d" % ix

func _format_with_key_hint(key_hint: String, label: String) -> String:
	# Use an en dash visually: "R – Parry"
	return ("%s – %s" % [key_hint, label]) if key_hint != "" else label


func _slot_fallback_key(ix: int) -> String:
	match ix:
		0: return "R"
		1: return "T"
		2: return "Y"
		_: return ""
