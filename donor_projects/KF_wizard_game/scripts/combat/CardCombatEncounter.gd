extends Encounter
class_name CardCombatEncounter
var _ui_for_player: bool = false
var _att_choice: CardDef = null
var _def_choice: CardDef = null
var _picking_for: Node3D = null   # who the UI is currently picking for (attacker/defender)
@export var debug_verbose: bool = false

# UI panel used for this encounter. Set by UIManager when opening.
var ui: CombatEncounterUI = null

# --- Fixed side mapping (You on the left, Enemy on the right) ---
var _you_actor: Node = null
var _enemy_actor: Node = null

# UI ownership
var _session_id: String = ""
# player-choice state
var _awaiting_choice: bool = false
var _saved_ix: int = -1
var _pending_anticipation: bool = false
var _need_initiative: bool = true

signal combat_log(msg: String)
signal combat_finished(winner: Node3D)

var rng: RandomNumberGenerator
var decks := {}               # Node3D -> DeckRuntime
var attacker: Node3D = null
var defender: Node3D = null
var initialized: bool = false
var anticipation_reduce_factor: float = 0.5

const CardDef         = preload("res://scripts/combat/CardDef.gd")
const Rules           = preload("res://scripts/combat/Rules.gd")
const DeckDefinition  = preload("res://scripts/combat/DeckDefinition.gd")
const DeckEntry       = preload("res://scripts/combat/DeckEntry.gd")
const DeckRuntime     = preload("res://scripts/combat/DeckRuntime.gd")
const CombatProfile   = preload("res://scripts/combat/CombatProfile.gd")

func set_ui(p_ui: CombatEncounterUI) -> void:
	ui = p_ui
	if debug_verbose:
		print("[CardCombatEncounter] set_ui -> %s" % ui)

func set_sides(you: Node, enemy: Node) -> void:
	_you_actor = you
	_enemy_actor = enemy
	if debug_verbose:
		print("[CardCombatEncounter] set_sides you=%s enemy=%s" % [you, enemy])
	_refresh_fixed_side_labels()

func _refresh_fixed_side_labels() -> void:
	if debug_verbose:
		print("[CardCombatEncounter] _refresh_fixed_side_labels ui=%s" % ui)
	if ui == null: return
	var y := _read_hp_pair(_you_actor)    # [current, max]
	var e := _read_hp_pair(_enemy_actor)
	ui.show_sides(_pretty_name(_you_actor), y[0], y[1], _pretty_name(_enemy_actor), e[0], e[1])

func _update_health_labels_now() -> void:
	if debug_verbose:
		print("[CardCombatEncounter] _update_health_labels_now")
	if ui == null: return
	var y := _read_hp_pair(_you_actor)
	var e := _read_hp_pair(_enemy_actor)
	ui.update_health(y[0], y[1], e[0], e[1])

func _set_round_role_label(attacker_is_you: bool) -> void:
	if ui == null: return
	ui.set_round_roles(attacker_is_you)

func _pretty_name(n: Node) -> String:
	if n == null: return "Unknown"
	# Prefer a display_name property if your character has one; fall back to node name.
	if n.has_method("get") and n.get("display_name") != null:
		return str(n.get("display_name"))
	return str(n.name)

func _read_hp_pair(n: Node) -> Array:
	# Returns [hp, max_hp] using whatever fields are present. Safe for 4.4.1.
	var hp := 0
	var max_hp := 0
	if n != null and n.has_method("get"):
		if n.get("runtime_health") != null:
			hp = int(n.get("runtime_health"))
		# try common max-health holders
		if n.get("max_health") != null:
			max_hp = int(n.get("max_health"))
		elif n.get("combat_profile") != null and n.get("combat_profile") != null:
			var prof = n.get("combat_profile")
			if prof != null and prof.has_method("get") and prof.get("max_health") != null:
				max_hp = int(prof.get("max_health"))
	# last resort: don't show 0/0 — assume 30 if unknown
	if max_hp <= 0:
		max_hp = max(hp, 30)
	return [hp, max_hp]


# ────────────────────────────────────────────────────────────────────
# Round driver (small, readable step)
# ────────────────────────────────────────────────────────────────────
func step() -> bool:
	if _awaiting_choice:
		return false
	if finished:
		return true
	if not initialized:
		_init_combat()

	if _need_initiative and not _awaiting_choice:
		_roll_initiative_once()

	if attacker == null or defender == null:
		# Not enough info yet (or waiting for UI to settle)
		return false

	# 1) draw
	_draw_hands()

	# 2) choose cards (may present UI and early-return)
	var att_card: CardDef = _choose_attacker_card()
	if att_card == null:
		return false
	var def_card: CardDef = _choose_defender_card()
	if def_card == null:
		return false

	# 3) resolve
	_resolve_round(att_card, def_card)
	if finished:
		return true

	# 4) end turn
	_end_turn()
	return false

func _choose_attacker_card() -> CardDef:
	if _att_choice != null:
		return _att_choice

	if _is_player(attacker):
		# If we're already waiting on the UI, just keep waiting
		if _awaiting_choice:
			return null

		# Open the UI once
		_awaiting_choice = true
		_picking_for = attacker
		var hand: Array = (decks[attacker] as DeckRuntime).hand
		if _ui_begin_choice(hand, Callable(self, "_on_ui_pick"), false, ""):
			if debug_verbose: print("[CardCombat] ATTACKER showing UI (no anticipation)")
			return null

		# No UI? fallback to AI
		_awaiting_choice = false

	# AI path (or UI unavailable)
	_att_choice = _ai_pick(attacker, defender)
	if debug_verbose: print("[CardCombat] ATTACKER AI pick -> ", _att_choice and _att_choice.name or "<null>")
	return _att_choice


func _choose_defender_card() -> CardDef:	
	if _def_choice != null:
		return _def_choice

	if _is_player(defender):
		if debug_verbose: print("[CardCombat] player is defnder and can chose a card")
		# Roll anticipation once, before showing UI
		## JS REMOVE 1
		#var anticipated_text := ""
		#if _att_choice != null:
			#var c := _att_choice as CardDef
			#if c != null and c.name != null and str(c.name) != "":
				#anticipated_text = str(c.name)
		## Push to UI before showing the hand
		#if anticipated_text != "":
			#_ui_set_anticipation(anticipated_text)
		#else:
			#_ui_clear_anticipation()
				#
		#if debug_verbose: print("[CardCombat] anticipated_text", anticipated_text)
		if _awaiting_choice:
			return null

		## setting all anticipation to true for testing
		_pending_anticipation = true
		_awaiting_choice = true
		_picking_for = defender
		var hand: Array = (decks[defender] as DeckRuntime).hand
		if _ui_begin_choice(hand, Callable(self, "_on_ui_pick"), _pending_anticipation, _att_choice.name):
			if debug_verbose: print("[CardCombat] DEFENDER showing UI (anticipated=%s)" % [str(_pending_anticipation)])
			return null

		# No UI? fallback to AI
		_awaiting_choice = false

	# AI path
	_def_choice = _ai_pick(defender, attacker)
	if debug_verbose: print("[CardCombat] DEFENDER AI pick -> ", _def_choice and _def_choice.name or "<null>")
	return _def_choice
	
func _resolve_round(att_card: CardDef, def_card: CardDef) -> void:
	var a_move: StringName = att_card.move_id
	var b_move: StringName = def_card.move_id

	var att_name := Rules.name_of(a_move)
	var def_name := Rules.name_of(b_move)

	_ui_log_line("%s uses %s; %s uses %s."
		% [attacker.name, att_name, defender.name, def_name])

	var res := Rules.outcome(a_move, b_move)  # { a_winner, a_die, b_die, label }

	# Roll both before applying: simultaneous damage
	var a_roll := Rules.roll_die(int(res["a_die"]), rng)  # attacker -> defender
	var b_roll := Rules.roll_die(int(res["b_die"]), rng)  # defender -> attacker

	_ui_log_line("%s. %s hits %s for %d. %s hits %s for %d."
		% [String(res["label"]), attacker.name, defender.name, a_roll, defender.name, attacker.name, b_roll])

	if a_roll > 0:
		_apply_damage(defender, a_roll, "%s deals %d to %s." % [attacker.name, a_roll, defender.name])
	if b_roll > 0:
		_apply_damage(attacker, b_roll, "%s deals %d to %s." % [defender.name, b_roll, attacker.name])

	_check_ko()


# CardCombatEncounter.gd
func _apply_damage(target: Node3D, dmg: int, line: String) -> void:
	var old_hp: int = int(target.get("runtime_health"))

	# Prefer the character's own damage pipeline so on_death fires correctly.
	if target != null and target.has_method("apply_damage"):
		# Pass the attacker as source so Character3D can log the killer.
		target.call("apply_damage", int(dmg), attacker)
	else:
		# Fallback: direct HP mutation (keeps old behavior), then ensure death hook runs.
		var new_hp: int = max(old_hp - int(dmg), 0)
		target.set("runtime_health", new_hp)
		if new_hp <= 0 and target.has_method("on_death"):
			target.call_deferred("on_death", attacker)

	_ui_log_line(line)
	var after_hp: int = int(target.get("runtime_health"))
	if debug_verbose: print("[CardCombat] DAMAGE target=", target.name, "  ", old_hp, " -> ", after_hp)
	_ui_update_status()

func _check_ko() -> void:
	if attacker == null or defender == null:
		return

	var att_hp := int(attacker.get("runtime_health"))
	var def_hp := int(defender.get("runtime_health"))
	if att_hp > 0 and def_hp > 0:
		return

	var winner := attacker
	if att_hp <= 0 and def_hp > 0:
		winner = defender
	elif def_hp <= 0 and att_hp > 0:
		winner = attacker
	else:
		# Double KO rule: attacker wins by default (tweak if you prefer)
		winner = attacker

	if debug_verbose: print("[CardCombat] KO! winner=", winner.name)
	result = {"winner": winner}
	combat_finished.emit(winner)

	# Ensure on_death is fired on dead parties (works with your Character3D.apply_damage pipeline)
	if def_hp <= 0 and is_instance_valid(defender) and defender.has_method("on_death"):
		defender.call_deferred("on_death", winner)
	if att_hp <= 0 and is_instance_valid(attacker) and attacker.has_method("on_death"):
		attacker.call_deferred("on_death", winner)

	# Close UI if the player was involved
	var player_involved := (is_instance_valid(attacker) and attacker.name == "PlayerCharacter") \
		or (is_instance_valid(defender) and defender.name == "PlayerCharacter")
	if player_involved:
		var tree := Engine.get_main_loop() as SceneTree
		if tree:
			var uim: Node = tree.get_first_node_in_group("ui_manager")
			if uim and uim.has_method("close_encounter_ui"):
				uim.call("close_encounter_ui", str(_session_id))

	end()


func _end_turn() -> void:
	_att_choice = null
	_def_choice = null
	_need_initiative = true
	_pending_anticipation = false
	_ui_update_status()
	_print_state("END_TURN")


# ────────────────────────────────────────────────────────────────────
# Misc utilities
# ────────────────────────────────────────────────────────────────────
func _swap_roles() -> void:
	var tmp: Node3D = attacker
	attacker = defender
	defender = tmp





func _draw_hands() -> void:
	var atk_dr: DeckRuntime = decks.get(attacker, null) as DeckRuntime
	var def_dr: DeckRuntime = decks.get(defender, null) as DeckRuntime
	if atk_dr == null or def_dr == null:
		_log("Missing runtime decks; ending encounter")
		end()
		return
	atk_dr.draw_until(atk_dr.hand_size, rng)
	def_dr.draw_until(def_dr.hand_size, rng)
	_ui_update_status()


func _get_uim() -> Node:
	var ml := Engine.get_main_loop()
	if ml is SceneTree:
		var root := (ml as SceneTree).root
		if root:
			return root.get_node_or_null("UIManager") # must match the Autoload node name
	return null

func _prompt_attacker_with_hand(hand: Array, anticipated: bool) -> void:
	if not _ui_for_player:
		# Fallback to AI pick if no human UI
		_ai_pick(attacker, defender)  # <- no 'var _ ='
		return

	var uim := _get_uim()
	if uim == null:
		_log("UIManager missing; cannot prompt player.")
		_ai_pick(attacker, defender)  # <- same here
		return

	_awaiting_choice = true
	uim.update_rps_status({
		"attacker_name": attacker.name,
		"defender_name": defender.name,
		"attacker_hp": int(attacker.get("runtime_health")),
		"attacker_max": int(attacker.get("combat_profile").base_health),
		"defender_hp": int(defender.get("runtime_health")),
		"defender_max": int(defender.get("combat_profile").base_health),
	})
	uim.begin_card_choice(hand, anticipated, Callable(self, "_on_ui_pick"))

# Returns true if we started a UI flow and should WAIT for the player's pick.
func _ui_begin_choice(hand: Array, on_pick: Callable, anticipated: bool, anticipatedCard: String) -> bool:
	var uim := _get_uim()
	if uim == null or not uim.has_method("begin_card_choice"):
		_log("UIManager missing begin_card_choice; cannot open hand UI.")
		return false
	uim.begin_card_choice(hand, anticipated, on_pick, anticipatedCard)
	return true


func _determine_ui_for_player() -> void:
	var present := false
	for p in participants:
		if p and (p.is_in_group("player") or (p.has_method("get") and p.get("is_player") == true)):
			present = true
			break
	_ui_for_player = present


func _on_ui_pick(ix: int) -> void:
	if debug_verbose: print("[CardCombat] received player pick =", ix)

	# If we know who we're picking for, immediately consume the card
	if _picking_for != null:
		var dr: DeckRuntime = decks.get(_picking_for, null)
		if dr != null:
			var chosen: CardDef = dr.play_index(ix)
			if _picking_for == attacker:
				_att_choice = chosen
				if debug_verbose: print("[CardCombat] ATTACKER player picked index=%d -> %s" % [ix, str(chosen != null)])
			else:
				_def_choice = chosen
				if debug_verbose: print("[CardCombat] DEFENDER player picked index=%d -> %s" % [ix, str(chosen != null)])
		_picking_for = null
		_awaiting_choice = false
		_saved_ix = -1
		return

	# Fallback (older flow): remember index only
	_saved_ix = ix
	_awaiting_choice = false


func _make_ui_ctx() -> Dictionary:
	var ctx: Dictionary = {}
	# attacker
	if attacker != null:
		ctx["attacker_name"] = str(attacker.name)
		var ahp := int(attacker.get("runtime_health"))
		var aprof = attacker.get("combat_profile")
		var amax := (int(aprof.base_health) if aprof != null else ahp)
		ctx["attacker_hp"]   = ahp
		ctx["attacker_max"]  = amax
	# defender
	if defender != null:
		ctx["defender_name"] = str(defender.name)
		var dhp := int(defender.get("runtime_health"))
		var dprof = defender.get("combat_profile")
		var dmax := (int(dprof.base_health) if dprof != null else dhp)
		ctx["defender_hp"]   = dhp
		ctx["defender_max"]  = dmax
	return ctx

func _ui_update_status() -> void:
	if not _ui_for_player:
		return
	var uim := _get_uim()
	if uim != null and uim.has_method("update_rps_status"):
		var ctx := _make_ui_ctx()
		ctx["session_id"] = _session_id
		uim.update_rps_status(ctx)


func _ui_log_line(msg: String) -> void:
	if not _ui_for_player:
		return
	var uim := _get_uim()
	if uim != null and uim.has_method("push_log"):
		uim.push_log(msg)



func start() -> void:
	# Call parent and then make sure we're initialized
	super.start()
	if not initialized:
		rng = RandomNumberGenerator.new()
		rng.randomize()
		_init_combat()
		_log("CardCombatEncounter start")


func _on_start() -> void:
	# Some Encounter bases call _on_start() after start(). Safe to (re)init once.
	if not initialized:
		rng = RandomNumberGenerator.new()
		rng.randomize()
		_init_combat()
		_log("CardCombatEncounter start (signal)")

func _init_combat() -> void:
	# Determine whether this encounter should talk to the UI at all
	_ui_for_player = false
	for p in participants:
		if _is_player(p):
			_ui_for_player = true
			break
	_session_id = str(Time.get_ticks_usec())  # simple, unique per encounter

	decks.clear()

	for p in participants:
		if p == null:
			continue

		# Ensure profile & HP exist
		var prof = p.get("combat_profile")
		if prof == null:
			_log("%s missing CombatProfile; using defaults" % p.name)
			prof = CombatProfile.new()
			p.set("combat_profile", prof)
		if int(p.get("runtime_health")) <= 0:
			p.set("runtime_health", int(prof.base_health))

		# Build runtime deck
		var dr = DeckRuntime.new()
		if prof.deck != null:
			dr.init_from(prof.deck, rng)
		else:
			# Fallback deck (small & simple) -- use property assignment (DeckEntry.new() takes no args)
			var dd = DeckDefinition.new()

			var e1 = DeckEntry.new()
			e1.card = _fallback_card("Fallback Thrust", &"thrust")
			e1.count = 34

			var e2 = DeckEntry.new()
			e2.card = _fallback_card("Fallback Parry",  &"parry")
			e2.count = 33

			var e3 = DeckEntry.new()
			e3.card = _fallback_card("Fallback Swing",  &"swing")
			e3.count = 33

			# Fill the deck definition
			if dd.has_method("add_entry"):
				dd.add_entry(e1)
				dd.add_entry(e2)
				dd.add_entry(e3)
			else:
				# If you prefer direct property assignment and the class exposes it:
				dd.entries = [e1, e2, e3]

			dd.hand_size = 3
			dr.init_from(dd, rng)

		_ensure_runtime_deck(dr, rng)
		decks[p] = dr
	if _ui_for_player: _ui_update_status()
	attacker = null
	defender = null
	_need_initiative = true
	initialized = true
	_print_state("INIT")

	# Optional helper for concise state dumps
func _print_state(tag: String) -> void:
	if not debug_verbose: return
	if attacker and defender:
		var ahp := int(attacker.get("runtime_health"))
		var dhp := int(defender.get("runtime_health"))
		if debug_verbose: print("[CardCombat][", tag, "] atk=", attacker.name, " HP=", ahp,
			  "  def=", defender.name, " HP=", dhp)

func _roll_initiative_once() -> void:
	if participants.size() < 2:
		return
	var p0: Node3D = participants[0]
	var p1: Node3D = participants[1]
	var s0: int = _get_skill(p0) + rng.randi_range(1, 10)
	var s1: int = _get_skill(p1) + rng.randi_range(1, 10)
	_log("Initiative %s=%d, %s=%d" % [p0.name, s0, p1.name, s1])

	# Higher goes first; on tie keep previous order if any, otherwise default to p0.
	if s0 == s1:
		if attacker == null:
			attacker = p0; defender = p1
		# else leave attacker/defender as-is
	elif s0 > s1:
		attacker = p0; defender = p1
	else:
		attacker = p1; defender = p0

	_need_initiative = false
	if _ui_for_player: _ui_update_status()





func _is_player(n: Node) -> bool:
	if n == null:
		return false
	if n.is_in_group("player"):
		return true
	var v = null
	if n.has_method("get"):
		v = n.get("is_player")
	# Only return true if the property is actually a boolean true.
	return typeof(v) == TYPE_BOOL and v



func _get_strength(p: Node3D) -> int:
	var prof = p.get("combat_profile")
	if prof != null:
		return int(prof.base_strength)
	return 5

func _get_skill(p: Node3D) -> int:
	var prof = p.get("combat_profile")
	if prof != null:
		return int(prof.base_skill)
	return 5

func _ai_pick(me: Node3D, _opp: Node3D):
	var dr = decks.get(me, null)
	if dr == null:
		return null
	var ix := 0
	if dr.hand.size() > 1:
		ix = rng.randi_range(0, dr.hand.size() - 1)
	var chosen = dr.play_index(ix)
	if chosen == null and dr.hand.size() > 0:
		chosen = dr.play_index(0)
	if chosen == null:
		dr.draw_until(1, rng)
		chosen = dr.play_index(0)
	return chosen



func _log(msg: String) -> void:
	if debug_verbose:
		print("[CardCombat] ", msg)
	combat_log.emit(msg)
	if _ui_for_player:
		_ui_log_line(msg)

func _fallback_card(name: String, move_id: StringName) -> CardDef:
	var c := CardDef.new()
	c.name = name
	c.move_id = move_id
	return c

func _ensure_runtime_deck(dr, rng: RandomNumberGenerator) -> void:
	# If the draw pile is empty (e.g., missing/empty profile deck), build a minimal fallback deck.
	if dr.draw_pile.is_empty():
		var dd = DeckDefinition.new()

		var e1 = DeckEntry.new()
		e1.card = _fallback_card("Fallback Thrust", &"thrust")
		e1.count = 34

		var e2 = DeckEntry.new()
		e2.card = _fallback_card("Fallback Parry",  &"parry")
		e2.count = 33

		var e3 = DeckEntry.new()
		e3.card = _fallback_card("Fallback Swing",  &"swing")
		e3.count = 33
		# Fill the deck definition
		if dd.has_method("add_entry"):
			dd.add_entry(e1)
			dd.add_entry(e2)
			dd.add_entry(e3)
		else:
			# If you prefer direct property assignment and the class exposes it:
			dd.entries = [e1, e2, e3]
		
		dd.hand_size = 3
		dr.init_from(dd, rng)


func _participants_include_player() -> bool:
	for p in participants:
		if _is_player(p):
			return true
	return false

func _on_player_card_choice(ix: int) -> void:
	if not _awaiting_choice:
		return
	_awaiting_choice = false
	_saved_ix = ix
	# Continue your old flow here (resolve round, roll dice, apply damage, log, etc.)

func _ui_set_anticipation(text: String) -> void:
	if debug_verbose: print("[CardCombat] trying to send anticipation", text)
	if ui:
		if debug_verbose: print("[CardCombat] HAS UI" )
	if ui and ui.has_method("set_anticipation_text"):
		if debug_verbose: print("[CardCombat] sending anticipation", text)
		ui.set_anticipation_text(text)
	if ui and not ui.has_method("set_anticipation_text"):
		if debug_verbose: print("[CardCombat] UI does not have method(set_anticipation_text)")

func _ui_clear_anticipation() -> void:
	if ui and ui.has_method("clear_anticipation"):
		ui.clear_anticipation()
