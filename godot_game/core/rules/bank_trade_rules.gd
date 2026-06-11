class_name BankTradeRules
extends RefCounted

const GIVE_AMOUNT := 4
const RECEIVE_AMOUNT := 1


static func can_trade(state: GameState, player_id: int, give_resource: ResourceType.Type, receive_resource: ResourceType.Type) -> bool:
	if give_resource == receive_resource:
		return false
	var player := _player(state, player_id)
	if player == null:
		return false
	return player.get_resource(give_resource) >= GIVE_AMOUNT


static func apply(
	state: GameState,
	player_id: int,
	give_resource: ResourceType.Type,
	receive_resource: ResourceType.Type
) -> Array:
	if not can_trade(state, player_id, give_resource, receive_resource):
		return []
	var player := _player(state, player_id)
	player.add_resource(give_resource, -GIVE_AMOUNT)
	player.add_resource(receive_resource, RECEIVE_AMOUNT)
	return [
		BankTradeEvent.new(
			state.round_number,
			player_id,
			give_resource,
			receive_resource,
			GIVE_AMOUNT,
			RECEIVE_AMOUNT
		),
	]


static func _player(state: GameState, player_id: int) -> Player:
	for player in state.players:
		if player.id == player_id:
			return player
	return null
