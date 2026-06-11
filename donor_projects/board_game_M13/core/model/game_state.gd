class_name GameState
extends RefCounted

var seed: int = 0
var turn_number: int = 0
var round_number: int = 1
var active_player_index: int = 0
var rng: GameRng = GameRng.new()
var board: HexBoard
var action_space: ActionSpace
var players: Array[Player] = []
var cities: Array[City] = []
var cities_by_vertex: Dictionary = {}
var breach_count: int = 0
var game_finished: bool = false
var winner_id: int = -1
