class_name TestBuildRuleLegality
extends RefCounted

## Intended build rules (post-setup):
## - Cities require resources, empty node, distance from other cities, and road-network connectivity.
## - Roads require resources, empty edge, and connectivity to own city/road network.
## - Illegal applies must not mutate authoritative state.
##
## 17 tests in 6 groups:
## - Setup baseline (2)
## - Core city legality (4)
## - Road legality (4)
## - ActionRules validation (3)
## - Bot policy behaviour (2)
## - CSV/export reporting (2)


static func run(test_assert: TestAssert) -> void:
	# --- Setup baseline ---
	_test_four_player_starts_with_four_cities(test_assert)
	_test_four_player_starts_with_zero_roads(test_assert)

	# --- Core city legality (LegalActionQuery / future BuildRules.can_build_city) ---
	_test_no_build_city_without_road_network_connection(test_assert)
	_test_cannot_build_city_on_occupied_node_query_and_apply(test_assert)
	_test_cannot_build_city_adjacent_to_existing_city(test_assert)
	_test_cannot_build_city_without_resources(test_assert)

	# --- Road legality (BuildRules + LegalActionQuery) ---
	_test_can_build_road_from_starting_city(test_assert)
	_test_successful_road_build_spends_resources_and_increments_count(test_assert)
	_test_cannot_build_road_on_occupied_edge(test_assert)
	_test_cannot_build_disconnected_road(test_assert)

	# --- ActionRules validation ---
	_test_illegal_build_city_apply_does_not_mutate_state(test_assert)
	_test_legal_query_and_action_rules_agree(test_assert)
	_test_legal_build_actions_never_make_resources_negative(test_assert)

	# --- Bot policy behaviour ---
	_test_bot_session_cities_remain_unique_vertices(test_assert)
	_test_bot_session_produces_road_built_events(test_assert)

	# --- CSV/export reporting ---
	_test_csv_city_built_actor_matches_event_player(test_assert)
	_test_csv_road_count_uses_replayed_state_on_road_built_rows(test_assert)


# --- Setup baseline ---


static func _test_four_player_starts_with_four_cities(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	test_assert.eq(state.cities.size(), 4, "[setup] four-player scenario should place exactly four starting cities")
	test_assert.eq(state.cities_by_vertex.size(), 4, "[setup] starting cities should occupy four unique nodes")


static func _test_four_player_starts_with_zero_roads(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	test_assert.eq(state.roads.size(), 0, "[setup] four-player scenario should start with zero roads")
	test_assert.eq(state.roads_by_edge.size(), 0, "[setup] four-player scenario should have no road edges occupied")


# --- Core city legality ---


static func _test_no_build_city_without_road_network_connection(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	var view := LegalActionQuery.get_view(state)
	var legal_count := _count_legal_build_cities(view, state)

	test_assert.eq(
		legal_count,
		0,
		"[city legality] expected 0 legal BUILD_CITY actions without road connection after setup, found %d"
		% legal_count
	)


static func _test_cannot_build_city_on_occupied_node_query_and_apply(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	var occupied_vertex := state.cities[0].vertex
	var action := _city_action_for_vertex(state, occupied_vertex)
	test_assert.check(action != null, "[city legality] fixture should locate BUILD_CITY action for occupied node")

	var view := LegalActionQuery.get_view(state)
	test_assert.check(
		not view.legal_mask[action.action_id],
		"[city legality] BUILD_CITY on occupied node should be illegal in LegalActionQuery"
	)

	var events := ActionRules.apply(state, action)
	test_assert.check(
		events.is_empty(),
		"[city legality] BUILD_CITY on occupied node should be rejected by ActionRules.apply"
	)


static func _test_cannot_build_city_adjacent_to_existing_city(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	var adjacent := _find_empty_vertex_adjacent_to_any_city(state)
	test_assert.check(adjacent != null, "[city legality] fixture should find an empty node adjacent to a starting city")

	var action := _city_action_for_vertex(state, adjacent)
	test_assert.check(action != null, "[city legality] action space should include adjacent empty node")

	var view := LegalActionQuery.get_view(state)
	test_assert.check(
		not view.legal_mask[action.action_id],
		"[city legality] BUILD_CITY adjacent to an existing city should be illegal (Catan-style distance rule)"
	)


static func _test_cannot_build_city_without_resources(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	var player := state.players[0]
	for resource in ResourceType.all():
		player.resources[resource] = 0

	var view := LegalActionQuery.get_view(state)
	var legal_when_broke := _count_legal_build_cities(view, state)
	test_assert.eq(
		legal_when_broke,
		0,
		"[city legality] expected 0 legal BUILD_CITY actions when player cannot afford cost, found %d"
		% legal_when_broke
	)


# --- Road legality ---


static func _test_can_build_road_from_starting_city(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	var player := state.players[0]
	var city_vertex := state.cities[0].vertex
	var edge := _first_edge_from_node(state, city_vertex)
	test_assert.check(edge != null, "[road legality] starting city should expose at least one edge")

	test_assert.check(
		BuildRules.can_build_road(state, player.id, edge),
		"[road legality] player should be able to build a road from their starting city when the edge is empty"
	)

	var action := _road_action_for_edge(state, edge)
	test_assert.check(action != null, "[road legality] action space should contain the road build action")
	var view := LegalActionQuery.get_view(state)
	test_assert.check(
		view.legal_mask[action.action_id],
		"[road legality] road from starting city should be legal when affordable"
	)


static func _test_successful_road_build_spends_resources_and_increments_count(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	var player := state.players[0]
	var wood_before := player.get_resource(ResourceType.Type.WOOD)
	var brick_before := player.get_resource(ResourceType.Type.BRICK)
	var roads_before := state.roads.size()

	var edge := _first_buildable_road_edge(state, player.id)
	test_assert.check(edge != null, "[road legality] fixture should find a buildable road edge")
	var action := _road_action_for_edge(state, edge)

	var events := ActionRules.apply(state, action)
	test_assert.check(not events.is_empty(), "[road legality] legal road build should apply")
	test_assert.eq(state.roads.size(), roads_before + 1, "[road legality] successful road build should increment road count")
	test_assert.check(
		player.get_resource(ResourceType.Type.WOOD) < wood_before,
		"[road legality] successful road build should spend wood"
	)
	test_assert.check(
		player.get_resource(ResourceType.Type.BRICK) < brick_before,
		"[road legality] successful road build should spend brick"
	)


static func _test_cannot_build_road_on_occupied_edge(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	var player := state.players[0]
	var edge := _first_buildable_road_edge(state, player.id)
	test_assert.check(edge != null, "[road legality] fixture should find a buildable road edge")
	state.roads_by_edge[edge.to_key()] = Road.new(99, edge)

	test_assert.check(
		not BuildRules.can_build_road(state, player.id, edge),
		"[road legality] occupied road edge should fail BuildRules.can_build_road"
	)

	var action := _road_action_for_edge(state, edge)
	var view := LegalActionQuery.get_view(state)
	test_assert.check(
		not view.legal_mask[action.action_id],
		"[road legality] BUILD_ROAD on occupied edge should be illegal in LegalActionQuery"
	)


static func _test_cannot_build_disconnected_road(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	var player := state.players[0]
	var disconnected := _find_disconnected_road_edge(state, player.id)
	test_assert.check(disconnected != null, "[road legality] fixture should find a disconnected empty edge")

	test_assert.check(
		not BuildRules.can_build_road(state, player.id, disconnected),
		"[road legality] disconnected road edge should fail BuildRules.can_build_road"
	)

	var action := _road_action_for_edge(state, disconnected)
	var view := LegalActionQuery.get_view(state)
	test_assert.check(
		not view.legal_mask[action.action_id],
		"[road legality] BUILD_ROAD on disconnected edge should be illegal in LegalActionQuery"
	)


# --- ActionRules validation ---


static func _test_illegal_build_city_apply_does_not_mutate_state(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	var occupied_vertex := state.cities[0].vertex
	var action := _city_action_for_vertex(state, occupied_vertex)
	var before := _state_snapshot(state)

	var events := ActionRules.apply(state, action)
	test_assert.check(
		events.is_empty(),
		"[ActionRules] illegal BUILD_CITY apply fixture should produce no events"
	)
	test_assert.eq(
		JSON.stringify(_state_snapshot(state)),
		JSON.stringify(before),
		"[ActionRules] illegal BUILD_CITY should not mutate city count, resources, score, or turn state"
	)


static func _test_legal_query_and_action_rules_agree(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	var rejected_legal_ids: Array[int] = []
	for action in LegalActionQuery.get_legal_actions_sorted(state):
		if action.kind == ActionKind.Kind.END_TURN:
			continue
		var probe := _clone_game_state(state)
		if ActionRules.apply(probe, action).is_empty():
			rejected_legal_ids.append(action.action_id)

	test_assert.check(
		rejected_legal_ids.is_empty(),
		"[ActionRules] ActionRules.apply rejected %d legal non-pass actions from LegalActionQuery (first ids: %s)"
		% [rejected_legal_ids.size(), _format_id_sample(rejected_legal_ids)]
	)

	var occupied := state.cities[0].vertex
	var illegal := _city_action_for_vertex(state, occupied)
	var probe_illegal := _clone_game_state(state)
	test_assert.check(
		ActionRules.apply(probe_illegal, illegal).is_empty(),
		"[ActionRules] ActionRules.apply should reject occupied-node BUILD_CITY that LegalActionQuery marks illegal"
	)


static func _test_legal_build_actions_never_make_resources_negative(test_assert: TestAssert) -> void:
	var state := ScenarioBuilder.build_four_player_bot_game(42)
	var negative_cases: Array[String] = []
	for action in LegalActionQuery.get_legal_actions_sorted(state):
		if action.kind not in [ActionKind.Kind.BUILD_CITY, ActionKind.Kind.BUILD_ROAD]:
			continue
		var probe := _clone_game_state(state)
		ActionRules.apply(probe, action)
		for player in probe.players:
			for resource in ResourceType.all():
				if player.get_resource(resource) < 0:
					negative_cases.append(
						"action_id=%d player=%d resource=%s"
						% [action.action_id, player.id, ResourceType.to_key(resource)]
					)

	test_assert.check(
		negative_cases.is_empty(),
		"[ActionRules] legal build actions should never drive resources negative (%d violations: %s)"
		% [negative_cases.size(), ", ".join(negative_cases.slice(0, 3))]
	)


# --- Bot policy behaviour ---


static func _test_bot_session_cities_remain_unique_vertices(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(42)
	session.run_until_finished(40)
	var duplicate_keys: Array[String] = []
	var seen := {}
	for city in session.state.cities:
		var key := city.vertex.to_key()
		if seen.has(key):
			duplicate_keys.append(key)
		seen[key] = true

	test_assert.check(
		duplicate_keys.is_empty(),
		"[bot policy] bot session should never place two cities on the same node (duplicates: %s)"
		% ", ".join(duplicate_keys)
	)


static func _test_bot_session_produces_road_built_events(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(42)
	session.run_until_finished(20)
	var road_built_count := 0
	for event in session.events:
		if event is RoadBuiltEvent:
			road_built_count += 1

	test_assert.check(
		road_built_count > 0,
		"[bot policy] expected bot session to produce at least one road_built event in 20 turns, found %d"
		% road_built_count
	)


# --- CSV/export reporting ---


static func _test_csv_city_built_actor_matches_event_player(test_assert: TestAssert) -> void:
	var session := BotGameSession.start_four_player(42)
	session.run_until_finished(12)
	var mismatches: Array[String] = []
	for row in PlaythroughCsvExporter.build_rows(session):
		if row.get("event_type", "") != "city_built":
			continue
		var payload: Dictionary = JSON.parse_string(str(row.get("event_details", "{}")))
		var event_player_id := int(payload.get("player_id", -1))
		var active_player_id := int(row.get("active_player_id", -1))
		if active_player_id != event_player_id:
			mismatches.append("event_player=%d active_player=%d" % [event_player_id, active_player_id])

	test_assert.check(
		mismatches.is_empty(),
		"[CSV export] city_built rows should match event player_id to active_player_id (%d mismatches, sample: %s)"
		% [mismatches.size(), ", ".join(mismatches.slice(0, 3))]
	)


static func _test_csv_road_count_uses_replayed_state_on_road_built_rows(test_assert: TestAssert) -> void:
	var session := _session_with_one_recorded_road_build()
	var bad_rows: Array[String] = []
	for row in PlaythroughCsvExporter.build_rows(session):
		if row.get("event_type", "") != "road_built":
			continue
		var road_count := int(row.get("road_count", "-1"))
		if road_count < 1:
			bad_rows.append("road_count=%d" % road_count)

	test_assert.check(
		bad_rows.is_empty(),
		"[CSV export] road_built rows should use replayed road_count >= 1, not final-state zero (%d bad rows: %s)"
		% [bad_rows.size(), ", ".join(bad_rows)]
	)


static func _session_with_one_recorded_road_build() -> BotGameSession:
	var session := BotGameSession.start_four_player(42)
	var edge := _first_buildable_road_edge(session.state, 0)
	var action := _road_action_for_edge(session.state, edge)
	for event in ActionRules.apply(session.state, action):
		session.events.append(event)
		session.event_log.append(event)
	return session


static func _count_legal_build_cities(view: LegalActionView, state: GameState) -> int:
	var count := 0
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.BUILD_CITY and view.legal_mask[action.action_id]:
			count += 1
	return count


static func _find_empty_vertex_adjacent_to_any_city(state: GameState) -> BoardNode:
	for city in state.cities:
		for neighbor in state.board.get_adjacent_nodes(city.vertex):
			if not state.cities_by_vertex.has(neighbor.to_key()):
				return neighbor
	return null


static func _find_disconnected_road_edge(state: GameState, player_id: int) -> EdgeCoord:
	for edge in state.board.get_all_edges_sorted():
		if state.roads_by_edge.has(edge.to_key()):
			continue
		if not BuildRules.can_build_road(state, player_id, edge):
			return edge
	return null


static func _first_edge_from_node(state: GameState, node: BoardNode) -> EdgeCoord:
	var edges := state.board.get_edges_for_node(node)
	if edges.is_empty():
		return null
	return edges[0]


static func _first_buildable_road_edge(state: GameState, player_id: int) -> EdgeCoord:
	for edge in state.board.get_all_edges_sorted():
		if BuildRules.can_build_road(state, player_id, edge):
			return edge
	return null


static func _city_action_for_vertex(state: GameState, vertex: BoardNode) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.BUILD_CITY and action.vertex.equals(vertex):
			return action
	return null


static func _road_action_for_edge(state: GameState, edge: EdgeCoord) -> GameAction:
	for action in state.action_space.all_actions_sorted():
		if action.kind == ActionKind.Kind.BUILD_ROAD and action.edge.equals(edge):
			return action
	return null


static func _format_id_sample(ids: Array[int]) -> String:
	if ids.is_empty():
		return "(none)"
	var sample: Array[String] = []
	for i in range(mini(5, ids.size())):
		sample.append(str(ids[i]))
	return ", ".join(sample)


static func _clone_game_state(state: GameState) -> GameState:
	var copy := ScenarioBuilder.build_four_player_bot_game(state.seed)
	copy.active_player_index = state.active_player_index
	copy.round_number = state.round_number
	copy.turn_number = state.turn_number
	copy.game_finished = state.game_finished
	copy.winner_id = state.winner_id
	copy.breach_count = state.breach_count
	copy.demon_counts_by_node = state.demon_counts_by_node.duplicate()
	copy.cities.clear()
	copy.cities_by_vertex.clear()
	for city in state.cities:
		SetupRules.place_city(copy, city.player_id, city.vertex)
	copy.roads.clear()
	copy.roads_by_edge.clear()
	for road in state.roads:
		SetupRules.place_road(copy, road.player_id, road.edge)
	for i in range(state.players.size()):
		for resource in ResourceType.all():
			copy.players[i].resources[resource] = state.players[i].get_resource(resource)
		copy.players[i].victory_points = state.players[i].victory_points
	return copy


static func _state_snapshot(state: GameState) -> Dictionary:
	var resources: Array = []
	var victory_points: Array = []
	for player in state.players:
		var row := {}
		for resource in ResourceType.all():
			row[ResourceType.to_key(resource)] = player.get_resource(resource)
		resources.append(row)
		victory_points.append(player.victory_points)
	return {
		"active_player_index": state.active_player_index,
		"round_number": state.round_number,
		"turn_number": state.turn_number,
		"city_count": state.cities.size(),
		"road_count": state.roads.size(),
		"resources": resources,
		"victory_points": victory_points,
	}
