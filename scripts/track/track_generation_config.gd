extends RefCounted
class_name TrackGenerationConfig

var track_layout: TrackLayoutResource
var track_width: float = 14.0
var grass_size: Vector2 = Vector2(260.0, 190.0)
var shoulder_width: float = 10.0
var barrier_distance_from_road: float = 12.0
var width_variation: float = 0.28
var has_stadium: bool = false
var stadium_section_step: int = 8
var stadium_distance_from_barrier: float = 24.0


static func from_layout(layout: TrackLayoutResource) -> TrackGenerationConfig:
	var config: TrackGenerationConfig = TrackGenerationConfig.new()
	config.track_layout = layout
	if layout != null:
		config.track_width = layout.track_width
		config.grass_size = layout.grass_size
		config.shoulder_width = layout.shoulder_width
		config.barrier_distance_from_road = layout.barrier_distance_from_road
		config.width_variation = layout.width_variation
		config.has_stadium = layout.has_stadium
		config.stadium_section_step = layout.stadium_section_step
		config.stadium_distance_from_barrier = layout.stadium_distance_from_barrier
	config.sanitize()
	return config


func duplicate_config() -> TrackGenerationConfig:
	var copy: TrackGenerationConfig = TrackGenerationConfig.new()
	copy.track_layout = track_layout
	copy.track_width = track_width
	copy.grass_size = grass_size
	copy.shoulder_width = shoulder_width
	copy.barrier_distance_from_road = barrier_distance_from_road
	copy.width_variation = width_variation
	copy.has_stadium = has_stadium
	copy.stadium_section_step = stadium_section_step
	copy.stadium_distance_from_barrier = stadium_distance_from_barrier
	copy.sanitize()
	return copy


func sanitize() -> void:
	track_width = maxf(track_width, 0.1)
	grass_size = Vector2(maxf(grass_size.x, 0.1), maxf(grass_size.y, 0.1))
	shoulder_width = maxf(shoulder_width, 0.0)
	barrier_distance_from_road = maxf(barrier_distance_from_road, 0.0)
	width_variation = clampf(width_variation, 0.0, 0.45)
	stadium_section_step = maxi(stadium_section_step, 1)
	stadium_distance_from_barrier = maxf(stadium_distance_from_barrier, 0.0)


func is_valid() -> bool:
	return track_layout != null and track_layout.is_valid()
