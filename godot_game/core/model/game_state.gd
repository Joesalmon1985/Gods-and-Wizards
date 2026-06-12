class_name GameState
extends RefCounted

var seed: int = 0
var turn_number: int = 0
var round_number: int = 1
var active_player_index: int = 0
var current_phase: TurnPhase.Phase = TurnPhase.Phase.ACTIVE_PLAYER
var turn_scope_flags: Dictionary = {}
var rng: GameRng = GameRng.new()
var board: HexBoard
var action_space: ActionSpace
var players: Array[Player] = []
var cities: Array[City] = []
var cities_by_vertex: Dictionary = {}
var roads: Array[Road] = []
var roads_by_edge: Dictionary = {}
var heroes: Array[Hero] = []
var heroes_by_id: Dictionary = {}
var heroes_by_node: Dictionary = {}
var demon_counts_by_node: Dictionary = {}
var infection_draw_pile: Array[String] = []
var infection_discard_pile: Array[String] = []
var infection_rate: int = 2
var city_demon_occupied_since_round: Dictionary = {}
var hero_actions_remaining: Dictionary = {}
var pending_trade_offers: Array = []
var next_trade_offer_id: int = 1
var trade_offers_made_this_turn: Array[String] = []
var draft_packs_by_player: Dictionary = {}
var draft_pending_picks: Dictionary = {}
var awaiting_draft_step: bool = false
var draft_age: int = 1
var draft_rounds_in_age: int = 0
var breach_count: int = 0
var game_finished: bool = false
var winner_id: int = -1
