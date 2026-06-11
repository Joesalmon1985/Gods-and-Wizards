class_name TestRegistry
extends RefCounted

const CATEGORY_UNIT := "unit"
const CATEGORY_INTEGRATION := "integration"
const CATEGORY_DETERMINISM := "determinism"
const CATEGORY_ARCHITECTURE := "architecture"
const CATEGORY_DEBUG := "debug"


static func all_modules() -> Array:
	return [
		{"category": CATEGORY_UNIT, "name": "TestBoardGeneration", "module": TestBoardGeneration},
		{"category": CATEGORY_UNIT, "name": "TestProductionChance", "module": TestProductionChance},
		{"category": CATEGORY_UNIT, "name": "TestVertexTopology", "module": TestVertexTopology},
		{"category": CATEGORY_INTEGRATION, "name": "TestProduction", "module": TestProduction},
		{"category": CATEGORY_DETERMINISM, "name": "TestDeterminism", "module": TestDeterminism},
		{"category": CATEGORY_UNIT, "name": "TestActionSpace", "module": TestActionSpace},
		{"category": CATEGORY_UNIT, "name": "TestTurnOrder", "module": TestTurnOrder},
		{"category": CATEGORY_INTEGRATION, "name": "TestLegalActions", "module": TestLegalActions},
		{"category": CATEGORY_INTEGRATION, "name": "TestActionApplication", "module": TestActionApplication},
		{"category": CATEGORY_INTEGRATION, "name": "TestBotPolicy", "module": TestBotPolicy},
		{"category": CATEGORY_INTEGRATION, "name": "TestHeuristicBot", "module": TestHeuristicBot},
		{"category": CATEGORY_INTEGRATION, "name": "TestScoring", "module": TestScoring},
		{"category": CATEGORY_INTEGRATION, "name": "TestGameOver", "module": TestGameOver},
		{"category": CATEGORY_INTEGRATION, "name": "TestBotSimulation", "module": TestBotSimulation},
		{"category": CATEGORY_INTEGRATION, "name": "TestEventLog", "module": TestEventLog},
		{"category": CATEGORY_DEBUG, "name": "TestEventLogReplay", "module": TestEventLogReplay},
		{"category": CATEGORY_ARCHITECTURE, "name": "TestArchitecture", "module": TestArchitecture},
		{"category": CATEGORY_DEBUG, "name": "TestDebugController", "module": TestDebugController},
		{"category": CATEGORY_DEBUG, "name": "TestDebugRunExport", "module": TestDebugRunExport},
	]


static func modules_for_category(category: String) -> Array:
	var filtered: Array = []
	for entry in all_modules():
		if entry["category"] == category:
			filtered.append(entry)
	return filtered


static func resolve_suite_filter() -> String:
	var args := OS.get_cmdline_user_args()
	var index := 0
	while index < args.size():
		var arg: String = args[index]
		if arg == "--suite" and index + 1 < args.size():
			return args[index + 1]
		if arg.begins_with("--suite="):
			return arg.substr("--suite=".length())
		index += 1
	return ""
