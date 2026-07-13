extends RefCounted
class_name OpponentSpawnLayout

var opponent_lane_spacing: float = 4.2
var opponent_row_spacing: float = 7.0


func configure(lane_spacing: float, row_spacing: float) -> void:
	opponent_lane_spacing = lane_spacing
	opponent_row_spacing = row_spacing


func get_spawn_transform(car_spawn: Node3D, opponent_index: int) -> Transform3D:
	if car_spawn == null:
		return Transform3D()

	var spawn_transform: Transform3D = car_spawn.global_transform
	var row: int = floori(float(opponent_index) / 2.0) + 1
	var lane_offset: float = get_lane_offset(opponent_index)
	spawn_transform.origin += spawn_transform.basis.x.normalized() * lane_offset
	spawn_transform.origin += spawn_transform.basis.z.normalized() * opponent_row_spacing * float(row)
	return spawn_transform


func get_lane_offset(opponent_index: int) -> float:
	var side_multiplier: float = -1.0 if opponent_index % 2 == 0 else 1.0
	return side_multiplier * opponent_lane_spacing * 0.5
