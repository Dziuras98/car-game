extends Resource
class_name TrackLayoutResource

@export_group("Identity")
@export var track_id: StringName = &"track"
@export var display_name: String = "Track"
@export_range(1, 99, 1) var recommended_laps: int = 3

@export_group("Layout")
@export var control_points: PackedVector3Array = PackedVector3Array()
@export_range(1, 64, 1) var samples_per_segment: int = 6

@export_group("Road")
@export var track_width: float = 14.0
@export var width_variation: float = 0.28
@export var shoulder_width: float = 10.0
@export var grass_size: Vector2 = Vector2(260.0, 190.0)
@export var barrier_distance_from_road: float = 12.0

@export_group("Decoration")
@export var has_stadium: bool = false
@export_range(4, 18, 1) var stadium_section_step: int = 8
@export var stadium_distance_from_barrier: float = 24.0


func is_valid() -> bool:
	return track_id != &"" and not display_name.strip_edges().is_empty() and control_points.size() >= 4
