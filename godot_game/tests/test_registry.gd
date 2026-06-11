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
		{"category": CATEGORY_UNIT, "name": "TestBoardNodeTopology", "module": TestBoardNodeTopology},
		{"category": CATEGORY_UNIT, "name": "TestEdgeTopology", "module": TestEdgeTopology},
		{"category": CATEGORY_INTEGRATION, "name": "TestProduction", "module": TestProduction},
		{"category": CATEGORY_DETERMINISM, "name": "TestDeterminism", "module": TestDeterminism},
		{"category": CATEGORY_UNIT, "name": "TestActionSpace", "module": TestActionSpace},
		{"category": CATEGORY_UNIT, "name": "TestActionSpaceRoads", "module": TestActionSpaceRoads},
		{"category": CATEGORY_UNIT, "name": "TestTurnOrder", "module": TestTurnOrder},
		{"category": CATEGORY_INTEGRATION, "name": "TestLegalActions", "module": TestLegalActions},
		{"category": CATEGORY_INTEGRATION, "name": "TestActionApplication", "module": TestActionApplication},
		{"category": CATEGORY_INTEGRATION, "name": "TestRoadBuild", "module": TestRoadBuild},
		{"category": CATEGORY_INTEGRATION, "name": "TestRoadLegality", "module": TestRoadLegality},
		{"category": CATEGORY_INTEGRATION, "name": "TestBuildRuleLegality", "module": TestBuildRuleLegality},
		{"category": CATEGORY_INTEGRATION, "name": "TestHeroMove", "module": TestHeroMove},
		{"category": CATEGORY_INTEGRATION, "name": "TestHeroOccupancy", "module": TestHeroOccupancy},
		{"category": CATEGORY_INTEGRATION, "name": "TestDemonSpread", "module": TestDemonSpread},
		{"category": CATEGORY_INTEGRATION, "name": "TestBreachEnd", "module": TestBreachEnd},
		{"category": CATEGORY_INTEGRATION, "name": "TestDevelopmentBuild", "module": TestDevelopmentBuild},
		{"category": CATEGORY_INTEGRATION, "name": "TestBotPolicy", "module": TestBotPolicy},
		{"category": CATEGORY_INTEGRATION, "name": "TestHeuristicBot", "module": TestHeuristicBot},
		{"category": CATEGORY_INTEGRATION, "name": "TestScoring", "module": TestScoring},
		{"category": CATEGORY_INTEGRATION, "name": "TestGameOver", "module": TestGameOver},
		{"category": CATEGORY_INTEGRATION, "name": "TestBotSimulation", "module": TestBotSimulation},
		{"category": CATEGORY_INTEGRATION, "name": "TestEventLog", "module": TestEventLog},
		{"category": CATEGORY_INTEGRATION, "name": "TestCombatRules", "module": TestCombatRules},
		{"category": CATEGORY_INTEGRATION, "name": "TestDeckRuntime", "module": TestDeckRuntime},
		{"category": CATEGORY_INTEGRATION, "name": "TestEncounterResolver", "module": TestEncounterResolver},
		{"category": CATEGORY_INTEGRATION, "name": "TestIntegrationBridge", "module": TestIntegrationBridge},
		{"category": CATEGORY_DEBUG, "name": "TestEventLogReplay", "module": TestEventLogReplay},
		{"category": CATEGORY_ARCHITECTURE, "name": "TestArchitecture", "module": TestArchitecture},
		{"category": CATEGORY_ARCHITECTURE, "name": "TestProjectLayout", "module": TestProjectLayout},
		{"category": CATEGORY_ARCHITECTURE, "name": "TestWorkspaceProjects", "module": TestWorkspaceProjects},
		{"category": CATEGORY_UNIT, "name": "TestBoardWorldMapper", "module": TestBoardWorldMapper},
		{"category": CATEGORY_UNIT, "name": "TestGameStateSummary", "module": TestGameStateSummary},
		{"category": CATEGORY_UNIT, "name": "TestEventSummary", "module": TestEventSummary},
		{"category": CATEGORY_ARCHITECTURE, "name": "TestBoardVisualization", "module": TestBoardVisualization},
		{"category": CATEGORY_INTEGRATION, "name": "TestRunModes", "module": TestRunModes},
		{"category": CATEGORY_INTEGRATION, "name": "TestHumanPlayerSession", "module": TestHumanPlayerSession},
		{"category": CATEGORY_INTEGRATION, "name": "TestMacroTrainingEnv", "module": TestMacroTrainingEnv},
		{"category": CATEGORY_INTEGRATION, "name": "TestBatchSim", "module": TestBatchSim},
		{"category": CATEGORY_INTEGRATION, "name": "TestBalanceConfig", "module": TestBalanceConfig},
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
