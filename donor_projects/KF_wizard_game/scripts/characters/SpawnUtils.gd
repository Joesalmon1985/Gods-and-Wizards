extends Object
class_name SpawnUtils

## Find the nearest collision-free point to `origin` on the hex top.
## Uses a cylinder the size of the player for clearance checks.
static func find_free_spawn(
	origin: Vector3,
	hex_top_y: float,
	search_limit: float,
	player_clearance_radius: float,
	space: PhysicsDirectSpaceState3D,
	collision_mask: int = 0x7FFFFFFF,
	max_rings: int = 12,
	samples_per_ring: int = 16
) -> Vector3:
	# shape matching the player's collider footprint
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = player_clearance_radius
	shape.height = 2.0

	var q: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.collision_mask = collision_mask

	# probe the exact center first (often blocked)
	q.transform = Transform3D(Basis(), Vector3(origin.x, hex_top_y + 0.05, origin.z))
	var hits: Array = space.intersect_shape(q, 1)
	if hits.is_empty():
		return q.transform.origin

	var step: float = max(player_clearance_radius * 1.3, 0.3)
	var ring: int = 1
	while ring <= max_rings:
		var r: float = min(step * float(ring), search_limit)
		var count: int = max(6, samples_per_ring * ring)  # more samples as we go out
		for i in range(count):
			var ang: float = TAU * float(i) / float(count)
			var p: Vector3 = Vector3(
				origin.x + cos(ang) * r,
				hex_top_y + 0.05,
				origin.z + sin(ang) * r
			)
			q.transform.origin = p
			hits = space.intersect_shape(q, 1)
			if hits.is_empty():
				return p
		ring += 1

	# fallback: hex edge along +X direction
	return Vector3(origin.x + search_limit, hex_top_y + 0.05, origin.z)
