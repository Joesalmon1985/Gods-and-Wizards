extends Object
class_name HexTile3D_Factory

# Use the class_name directly; no need to preload the script.
# (HexTile3D_Base must have: class_name HexTile3D_Base)
const SCENES := {
	"WOOD":  preload("res://scenes/tiles/Hex3D_Wood.tscn"),
	"BRICK": preload("res://scenes/tiles/Hex3D_Brick.tscn"),
	"ORE":   preload("res://scenes/tiles/Hex3D_Ore.tscn"),
	"WHEAT": preload("res://scenes/tiles/Hex3D_Wheat.tscn"),
	"SHEEP": preload("res://scenes/tiles/Hex3D_Sheep.tscn"),
	"DESERT":preload("res://scenes/tiles/Hex3D_Desert.tscn"),
}

static func instantiate_for(resource: String, q: int, r: int, radius: float, height: float) -> Node3D:
	# Dictionary.get() returns Variant; cast to the expected type.
	var scene: PackedScene = SCENES.get(resource) as PackedScene

	var node: Node3D
	if scene:
		node = scene.instantiate() as Node3D
	else:
		node = Node3D.new()

	if node is HexTile3D_Base:
		var env: HexTile3D_Base = node
		env.resource = resource
		env.axial_q = q
		env.axial_r = r
		env.radius = radius
		env.height = height

	return node
