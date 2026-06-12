class_name GameStateSummary
extends RefCounted

const MODE_TITLE := "Wizard World Mode"


static func build(state: GameState, session: BotGameSession = null) -> Dictionary:
	var player_turns := session.player_turn_count if session != null else 0
	var seed := session.seed if session != null else state.seed
	return {
		"title": MODE_TITLE,
		"seed": seed,
		"round_number": state.round_number,
		"turn_number": player_turns,
		"active_player_name": _active_player_name(state),
		"active_player_id": state.active_player_index,
		"phase": TurnPhase.to_key(state.current_phase),
		"total_cities": state.cities.size(),
		"total_roads": state.roads.size(),
		"total_demons": _total_demons(state),
		"breach_count": state.breach_count,
		"breach_limit": GameConstants.BREACH_LIMIT,
		"game_finished": state.game_finished,
		"winner_name": _winner_name(state),
		"leader_name": _leader_name(state),
		"leader_vp": _leader_vp(state),
		"players": _player_rows(state),
		"infection_rate": state.infection_rate,
		"draft_age": state.draft_age,
		"hero_actions_remaining": state.hero_actions_remaining.duplicate(),
	}


static func format_header(summary: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append("%s" % summary.get("title", MODE_TITLE))
	lines.append(
		"Seed %d | Round %d | Turn %d | Active: %s | Phase: %s" % [
			summary.get("seed", 0),
			summary.get("round_number", 0),
			summary.get("turn_number", 0),
			summary.get("active_player_name", "?"),
			summary.get("phase", ""),
		]
	)
	lines.append(
		"Cities: %d | Roads: %d | Demons: %d | Breach: %d/%d" % [
			summary.get("total_cities", 0),
			summary.get("total_roads", 0),
			summary.get("total_demons", 0),
			summary.get("breach_count", 0),
			summary.get("breach_limit", GameConstants.BREACH_LIMIT),
		]
	)
	if summary.get("game_finished", false):
		var winner: String = summary.get("winner_name", "")
		if winner != "":
			lines.append("Game over — winner: %s" % winner)
		else:
			lines.append("Game over — shared loss (underworld breach).")
	else:
		lines.append("Leader: %s (%d VP)" % [summary.get("leader_name", "?"), summary.get("leader_vp", 0)])
	return "\n".join(lines)


static func format_scoreboard(summary: Dictionary) -> String:
	var lines: PackedStringArray = ["Scoreboard:"]
	for row in summary.get("players", []):
		lines.append(
			"  %s — %d VP | cities %d | roads %d | hero %s" % [
				row.get("name", "?"),
				row.get("victory_points", 0),
				row.get("city_count", 0),
				row.get("road_count", 0),
				row.get("hero_status", "—"),
			]
		)
		lines.append(
			"    Wood %d | Brick %d | Wheat %d | Sheep %d | Ore %d" % [
				row.get("wood", 0),
				row.get("brick", 0),
				row.get("wheat", 0),
				row.get("sheep", 0),
				row.get("ore", 0),
			]
		)
	return "\n".join(lines)


static func _player_rows(state: GameState) -> Array:
	var cities_by_player := {}
	var roads_by_player := {}
	var heroes_by_player := {}

	for city in state.cities:
		cities_by_player[city.player_id] = int(cities_by_player.get(city.player_id, 0)) + 1
	for road in state.roads:
		roads_by_player[road.player_id] = int(roads_by_player.get(road.player_id, 0)) + 1
	for hero in state.heroes:
		heroes_by_player[hero.player_id] = "at %s" % hero.node.to_key().split("|")[0]

	var rows: Array = []
	for player in state.players:
		rows.append({
			"id": player.id,
			"name": player.display_name,
			"victory_points": player.victory_points,
			"city_count": int(cities_by_player.get(player.id, 0)),
			"road_count": int(roads_by_player.get(player.id, 0)),
			"hero_status": str(heroes_by_player.get(player.id, "—")),
			"wood": player.get_resource(ResourceType.Type.WOOD),
			"brick": player.get_resource(ResourceType.Type.BRICK),
			"wheat": player.get_resource(ResourceType.Type.WHEAT),
			"sheep": player.get_resource(ResourceType.Type.SHEEP),
			"ore": player.get_resource(ResourceType.Type.ORE),
		})
	return rows


static func _active_player_name(state: GameState) -> String:
	var player := TurnRules.get_active_player(state)
	if player == null:
		return "?"
	return player.display_name


static func _total_demons(state: GameState) -> int:
	var total := 0
	for key in state.demon_counts_by_node.keys():
		total += int(state.demon_counts_by_node[key])
	return total


static func _winner_name(state: GameState) -> String:
	if not state.game_finished or state.winner_id < 0:
		return ""
	for player in state.players:
		if player.id == state.winner_id:
			return player.display_name
	return ""


static func _leader_name(state: GameState) -> String:
	var leader_id := _leader_id(state)
	for player in state.players:
		if player.id == leader_id:
			return player.display_name
	return "?"


static func _leader_vp(state: GameState) -> int:
	var leader_id := _leader_id(state)
	for player in state.players:
		if player.id == leader_id:
			return player.victory_points
	return 0


static func _leader_id(state: GameState) -> int:
	var best_id := 0
	var best_vp := -1
	for player in state.players:
		if player.victory_points > best_vp:
			best_vp = player.victory_points
			best_id = player.id
	return best_id
