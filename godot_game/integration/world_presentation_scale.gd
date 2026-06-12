class_name WorldPresentationScale
extends RefCounted

const HEX_SIZE := 16.0
const BASE_HEX_SIZE := 1.0
const SCALE_FACTOR := HEX_SIZE / BASE_HEX_SIZE

const HEX_RADIUS_RATIO := 0.42
const NODE_MARKER_HEIGHT_RATIO := 0.12
const CITY_HEIGHT_RATIO := 0.55
const HERO_HEIGHT_RATIO := 0.45
const DEMON_HEIGHT_RATIO := 0.35
const BASE_ENCOUNTER_RADIUS := 6.0
const BASE_BOARD_HEIGHT := 28.0
const BASE_WIZARD_EYE_HEIGHT := 1.6
const BASE_WIZARD_BACK_OFFSET := 2.5


static func hex_centre_spacing() -> float:
	return sqrt(3.0) * HEX_SIZE


static func five_hex_distance() -> float:
	return 5.0 * hex_centre_spacing()


static func walk_speed() -> float:
	return five_hex_distance() / 180.0


static func hex_radius() -> float:
	return HEX_RADIUS_RATIO * HEX_SIZE


static func node_marker_height() -> float:
	return NODE_MARKER_HEIGHT_RATIO * HEX_SIZE


static func city_height() -> float:
	return CITY_HEIGHT_RATIO * HEX_SIZE


static func hero_height() -> float:
	return HERO_HEIGHT_RATIO * HEX_SIZE


static func demon_height() -> float:
	return DEMON_HEIGHT_RATIO * HEX_SIZE


static func board_height() -> float:
	return BASE_BOARD_HEIGHT * SCALE_FACTOR


static func wizard_eye_height() -> float:
	return BASE_WIZARD_EYE_HEIGHT * SCALE_FACTOR


static func wizard_back_offset() -> float:
	return BASE_WIZARD_BACK_OFFSET * SCALE_FACTOR


static func encounter_radius() -> float:
	return BASE_ENCOUNTER_RADIUS * SCALE_FACTOR


static func floor_plane_size() -> float:
	return 24.0 * SCALE_FACTOR
