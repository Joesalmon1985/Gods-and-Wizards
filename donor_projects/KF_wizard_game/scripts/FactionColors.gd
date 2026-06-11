extends Node
class_name FactionColors

# 8 distinct, high-contrast colours (works in 2D & 3D).
const COLORS := [
	Color(0.90, 0.20, 0.20), # 0 Red
	Color(0.20, 0.50, 0.90), # 1 Blue
	Color(0.20, 0.80, 0.30), # 2 Green
	Color(0.95, 0.85, 0.20), # 3 Yellow
	Color(0.70, 0.30, 0.90), # 4 Purple
	Color(0.95, 0.50, 0.20), # 5 Orange
	Color(0.20, 0.90, 0.90), # 6 Cyan
	Color(0.90, 0.90, 0.90), # 7 White
]
const FALLBACK := Color(0.50, 0.50, 0.50)

static func player_color(faction: int) -> Color:
	if faction >= 0 and faction < COLORS.size():
		return COLORS[faction]
	return FALLBACK

# Alias to keep older calls working:
static func get_color(faction: int) -> Color:
	return player_color(faction)
