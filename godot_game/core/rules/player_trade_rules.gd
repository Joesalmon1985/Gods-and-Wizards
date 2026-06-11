class_name PlayerTradeRules
extends RefCounted

const TRADE_AMOUNT := 1


static func can_trade(
	state: GameState,
	active_player_id: int,
	partner_player_id: int,
	give_resource: ResourceType.Type,
	receive_resource: ResourceType.Type
) -> bool:
	if give_resource == receive_resource:
		return false
	if partner_player_id < 0 or partner_player_id == active_player_id:
		return false
	var active := _player(state, active_player_id)
	var partner := _player(state, partner_player_id)
	if active == null or partner == null:
		return false
	return (
		active.get_resource(give_resource) >= TRADE_AMOUNT
		and partner.get_resource(receive_resource) >= TRADE_AMOUNT
	)


static func apply(
	state: GameState,
	active_player_id: int,
	partner_player_id: int,
	give_resource: ResourceType.Type,
	receive_resource: ResourceType.Type
) -> Array:
	if not can_trade(state, active_player_id, partner_player_id, give_resource, receive_resource):
		return []
	var active := _player(state, active_player_id)
	var partner := _player(state, partner_player_id)
	active.add_resource(give_resource, -TRADE_AMOUNT)
	active.add_resource(receive_resource, TRADE_AMOUNT)
	partner.add_resource(receive_resource, -TRADE_AMOUNT)
	partner.add_resource(give_resource, TRADE_AMOUNT)
	return [
		PlayerTradeEvent.new(
			state.round_number,
			active_player_id,
			partner_player_id,
			give_resource,
			receive_resource,
			TRADE_AMOUNT
		),
	]


static func _player(state: GameState, player_id: int) -> Player:
	for player in state.players:
		if player.id == player_id:
			return player
	return null
