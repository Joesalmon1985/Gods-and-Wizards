class_name WizardOrientation
extends RefCounted


static func forward(yaw_rad: float) -> Vector3:
	return Vector3(sin(yaw_rad), 0.0, cos(yaw_rad))


static func right(yaw_rad: float) -> Vector3:
	return Vector3(cos(yaw_rad), 0.0, -sin(yaw_rad))
