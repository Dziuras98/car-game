extends StaticBody3D
class_name TrackSurfaceBody

const MIN_GRIP_MULTIPLIER: float = 0.05
const MAX_GRIP_MULTIPLIER: float = 2.0

@export_range(MIN_GRIP_MULTIPLIER, MAX_GRIP_MULTIPLIER, 0.01) var grip_multiplier: float = 1.0


func get_grip_multiplier() -> float:
	return clampf(grip_multiplier, MIN_GRIP_MULTIPLIER, MAX_GRIP_MULTIPLIER)
