class_name GameAction
extends RefCounted

var action_id: int = -1
var kind: ActionKind.Kind = ActionKind.Kind.END_TURN
var vertex: BoardNode = null
var edge: EdgeCoord = null
var hero_id: int = -1
var target_node: BoardNode = null
var give_resource: ResourceType.Type = ResourceType.Type.WOOD
var receive_resource: ResourceType.Type = ResourceType.Type.WOOD
var partner_player_id: int = -1
var give_amount: int = 1
var request_amount: int = 1
var trade_offer_id: int = -1
var development_id: String = ""


func _init(
	p_action_id: int = -1,
	p_kind: ActionKind.Kind = ActionKind.Kind.END_TURN,
	p_vertex: BoardNode = null,
	p_edge: EdgeCoord = null,
	p_hero_id: int = -1,
	p_target_node: BoardNode = null,
	p_give_resource: ResourceType.Type = ResourceType.Type.WOOD,
	p_receive_resource: ResourceType.Type = ResourceType.Type.WOOD,
	p_partner_player_id: int = -1
) -> void:
	action_id = p_action_id
	kind = p_kind
	vertex = p_vertex
	edge = p_edge
	hero_id = p_hero_id
	target_node = p_target_node
	give_resource = p_give_resource
	receive_resource = p_receive_resource
	partner_player_id = p_partner_player_id


func equals(other: GameAction) -> bool:
	if other == null:
		return false
	if action_id != other.action_id or kind != other.kind:
		return false
	match kind:
		ActionKind.Kind.BUILD_CITY:
			if vertex == null or other.vertex == null:
				return false
			return vertex.equals(other.vertex)
		ActionKind.Kind.BUILD_DEVELOPMENT:
			if vertex == null or other.vertex == null:
				return false
			return vertex.equals(other.vertex) and development_id == other.development_id
		ActionKind.Kind.BUILD_ROAD:
			if edge == null or other.edge == null:
				return false
			return edge.equals(other.edge)
		ActionKind.Kind.MOVE_HERO:
			return hero_id == other.hero_id and target_node != null and other.target_node != null and target_node.equals(other.target_node)
		ActionKind.Kind.BANK_TRADE:
			return give_resource == other.give_resource and receive_resource == other.receive_resource
		ActionKind.Kind.PLAYER_TRADE:
			return (
				partner_player_id == other.partner_player_id
				and give_resource == other.give_resource
				and receive_resource == other.receive_resource
			)
		_:
			return true


func to_dict() -> Dictionary:
	var data := {
		"action_id": action_id,
		"kind": ActionKind.to_key(kind),
	}
	if kind in [ActionKind.Kind.BUILD_CITY, ActionKind.Kind.BUILD_DEVELOPMENT] and vertex != null:
		data["vertex"] = vertex.to_dict()
	if kind == ActionKind.Kind.BUILD_ROAD and edge != null:
		data["edge"] = edge.to_dict()
	if kind == ActionKind.Kind.MOVE_HERO:
		data["hero_id"] = hero_id
		if target_node != null:
			data["target_node"] = target_node.to_dict()
	if kind == ActionKind.Kind.BANK_TRADE:
		data["give_resource"] = ResourceType.to_key(give_resource)
		data["receive_resource"] = ResourceType.to_key(receive_resource)
	if kind == ActionKind.Kind.PLAYER_TRADE:
		data["give_resource"] = ResourceType.to_key(give_resource)
		data["receive_resource"] = ResourceType.to_key(receive_resource)
		data["partner_player_id"] = partner_player_id
	return data


static func from_dict(data: Dictionary) -> GameAction:
	var kind := _kind_from_key(data.get("kind", ""))
	var vertex: BoardNode = null
	var edge: EdgeCoord = null
	var target_node: BoardNode = null
	if kind in [ActionKind.Kind.BUILD_CITY, ActionKind.Kind.BUILD_DEVELOPMENT] and data.has("vertex"):
		vertex = BoardNode.from_dict(data["vertex"])
	if kind == ActionKind.Kind.BUILD_ROAD and data.has("edge"):
		edge = EdgeCoord.from_dict(data["edge"])
	if kind == ActionKind.Kind.MOVE_HERO and data.has("target_node"):
		target_node = BoardNode.from_dict(data["target_node"])
	return GameAction.new(
		data.get("action_id", -1),
		kind,
		vertex,
		edge,
		data.get("hero_id", -1),
		target_node,
		_resource_from_key(data.get("give_resource", "")),
		_resource_from_key(data.get("receive_resource", "")),
		int(data.get("partner_player_id", -1))
	)


static func _resource_from_key(key: String) -> ResourceType.Type:
	match key:
		"wood":
			return ResourceType.Type.WOOD
		"brick":
			return ResourceType.Type.BRICK
		"wheat":
			return ResourceType.Type.WHEAT
		"sheep":
			return ResourceType.Type.SHEEP
		"ore":
			return ResourceType.Type.ORE
		_:
			return ResourceType.Type.WOOD


static func _kind_from_key(key: String) -> ActionKind.Kind:
	match key:
		"end_turn":
			return ActionKind.Kind.END_TURN
		"build_city":
			return ActionKind.Kind.BUILD_CITY
		"build_road":
			return ActionKind.Kind.BUILD_ROAD
		"move_hero":
			return ActionKind.Kind.MOVE_HERO
		"build_development":
			return ActionKind.Kind.BUILD_DEVELOPMENT
		"bank_trade":
			return ActionKind.Kind.BANK_TRADE
		"player_trade":
			return ActionKind.Kind.PLAYER_TRADE
		_:
			return ActionKind.Kind.END_TURN
