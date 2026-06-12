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
		{"category": CATEGORY_INTEGRATION, "name": "TestTurnLifecycle", "module": TestTurnLifecycle},
		{"category": CATEGORY_INTEGRATION, "name": "TestLegalActions", "module": TestLegalActions},
		{"category": CATEGORY_INTEGRATION, "name": "TestActionApplication", "module": TestActionApplication},
		{"category": CATEGORY_INTEGRATION, "name": "TestRoadBuild", "module": TestRoadBuild},
		{"category": CATEGORY_INTEGRATION, "name": "TestRoadLegality", "module": TestRoadLegality},
		{"category": CATEGORY_INTEGRATION, "name": "TestBuildRuleLegality", "module": TestBuildRuleLegality},
		{"category": CATEGORY_INTEGRATION, "name": "TestHeroMove", "module": TestHeroMove},
		{"category": CATEGORY_INTEGRATION, "name": "TestMacroContactResolution", "module": TestMacroContactResolution},
		{"category": CATEGORY_INTEGRATION, "name": "TestHeroActionBudget", "module": TestHeroActionBudget},
		{"category": CATEGORY_INTEGRATION, "name": "TestHeroOccupancy", "module": TestHeroOccupancy},
		{"category": CATEGORY_INTEGRATION, "name": "TestDemonSpread", "module": TestDemonSpread},
		{"category": CATEGORY_INTEGRATION, "name": "TestInfectionDeckSpread", "module": TestInfectionDeckSpread},
		{"category": CATEGORY_INTEGRATION, "name": "TestCityDemonOccupation", "module": TestCityDemonOccupation},
		{"category": CATEGORY_INTEGRATION, "name": "TestBreachEnd", "module": TestBreachEnd},
		{"category": CATEGORY_INTEGRATION, "name": "TestDevelopmentBuild", "module": TestDevelopmentBuild},
		{"category": CATEGORY_UNIT, "name": "TestDevelopmentEffectEngine", "module": TestDevelopmentEffectEngine},
		{"category": CATEGORY_INTEGRATION, "name": "TestDevelopmentPerCardCost", "module": TestDevelopmentPerCardCost},
		{"category": CATEGORY_INTEGRATION, "name": "TestDraftSession", "module": TestDraftSession},
		{"category": CATEGORY_UNIT, "name": "TestDraftAgeDeckShuffle", "module": TestDraftAgeDeckShuffle},
		{"category": CATEGORY_UNIT, "name": "TestDraftPackDeal", "module": TestDraftPackDeal},
		{"category": CATEGORY_INTEGRATION, "name": "TestDraftAgeAdvance", "module": TestDraftAgeAdvance},
		{"category": CATEGORY_DETERMINISM, "name": "TestDraftDeterminism", "module": TestDraftDeterminism},
		{"category": CATEGORY_INTEGRATION, "name": "TestDraftPickApply", "module": TestDraftPickApply},
		{"category": CATEGORY_INTEGRATION, "name": "TestDraftPickLegality", "module": TestDraftPickLegality},
		{"category": CATEGORY_INTEGRATION, "name": "TestDraftBotPolicy", "module": TestDraftBotPolicy},
		{"category": CATEGORY_INTEGRATION, "name": "TestDraftSessionHuman", "module": TestDraftSessionHuman},
		{"category": CATEGORY_INTEGRATION, "name": "TestDevelopmentCatalog", "module": TestDevelopmentCatalog},
		{"category": CATEGORY_UNIT, "name": "TestDevelopmentEffectType", "module": TestDevelopmentEffectType},
		{"category": CATEGORY_UNIT, "name": "TestDevelopmentCardDefinition", "module": TestDevelopmentCardDefinition},
		{"category": CATEGORY_UNIT, "name": "TestDevelopmentCatalogValidator", "module": TestDevelopmentCatalogValidator},
		{"category": CATEGORY_INTEGRATION, "name": "TestDevelopmentCatalogLoader", "module": TestDevelopmentCatalogLoader},
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
		{"category": CATEGORY_ARCHITECTURE, "name": "TestStrategicBoardView", "module": TestStrategicBoardView},
		{"category": CATEGORY_ARCHITECTURE, "name": "TestStrategicAuditMode", "module": TestStrategicAuditMode},
		{"category": CATEGORY_ARCHITECTURE, "name": "TestHumanMacro2DMode", "module": TestHumanMacro2DMode},
		{"category": CATEGORY_INTEGRATION, "name": "TestStrategicPlayIntegration", "module": TestStrategicPlayIntegration},
		{"category": CATEGORY_ARCHITECTURE, "name": "TestMacroSpectator3DMode", "module": TestMacroSpectator3DMode},
		{"category": CATEGORY_ARCHITECTURE, "name": "TestSpellCombatTimelinePresenter", "module": TestSpellCombatTimelinePresenter},
		{"category": CATEGORY_ARCHITECTURE, "name": "TestPlayableMicroCombat", "module": TestPlayableMicroCombat},
		{"category": CATEGORY_INTEGRATION, "name": "TestRunModes", "module": TestRunModes},
		{"category": CATEGORY_INTEGRATION, "name": "TestPlaythroughCsvExporter", "module": TestPlaythroughCsvExporter},
		{"category": CATEGORY_INTEGRATION, "name": "TestHeadlessDuelRunner", "module": TestHeadlessDuelRunner},
		{"category": CATEGORY_INTEGRATION, "name": "TestHumanPlayerSession", "module": TestHumanPlayerSession},
		{"category": CATEGORY_INTEGRATION, "name": "TestBankTrade", "module": TestBankTrade},
		{"category": CATEGORY_INTEGRATION, "name": "TestTradeOfferAccept", "module": TestTradeOfferAccept},
		{"category": CATEGORY_INTEGRATION, "name": "TestMacroTrainingEnv", "module": TestMacroTrainingEnv},
		{"category": CATEGORY_INTEGRATION, "name": "TestMacroTrainingTelemetry", "module": TestMacroTrainingTelemetry},
		{"category": CATEGORY_INTEGRATION, "name": "TestSpellCatalog", "module": TestSpellCatalog},
		{"category": CATEGORY_INTEGRATION, "name": "TestSpellCombatSession", "module": TestSpellCombatSession},
		{"category": CATEGORY_INTEGRATION, "name": "TestMicroCombatTelemetry", "module": TestMicroCombatTelemetry},
		{"category": CATEGORY_INTEGRATION, "name": "TestBatchSim", "module": TestBatchSim},
		{"category": CATEGORY_INTEGRATION, "name": "TestUnderworldPressure", "module": TestUnderworldPressure},
		{"category": CATEGORY_INTEGRATION, "name": "TestBalanceConfig", "module": TestBalanceConfig},
		{"category": CATEGORY_DEBUG, "name": "TestDebugController", "module": TestDebugController},
		{"category": CATEGORY_DEBUG, "name": "TestDebugRunExport", "module": TestDebugRunExport},
		{"category": CATEGORY_DEBUG, "name": "TestTestRunner", "module": TestTestRunner},
	]


static func modules_for_category(category: String) -> Array:
	var filtered: Array = []
	for entry in all_modules():
		if entry["category"] == category:
			filtered.append(entry)
	return filtered


static func modules_for_name(module_name: String) -> Array:
	var filtered: Array = []
	for entry in all_modules():
		if entry["name"] == module_name:
			filtered.append(entry)
	return filtered


static func parse_cmdline_filters(args: Array) -> Dictionary:
	var result := {"suite": "", "module": ""}
	var index := 0
	while index < args.size():
		var arg: String = args[index]
		if arg == "--suite" and index + 1 < args.size():
			result["suite"] = args[index + 1]
			index += 2
			continue
		if arg.begins_with("--suite="):
			result["suite"] = arg.substr("--suite=".length())
			index += 1
			continue
		if arg == "--module" and index + 1 < args.size():
			result["module"] = args[index + 1]
			index += 2
			continue
		if arg.begins_with("--module="):
			result["module"] = arg.substr("--module=".length())
			index += 1
			continue
		index += 1
	return result


static func resolve_suite_filter() -> String:
	return parse_cmdline_filters(OS.get_cmdline_user_args())["suite"]


static func resolve_module_filter() -> String:
	return parse_cmdline_filters(OS.get_cmdline_user_args())["module"]
