extends Resource
class_name TrackLayoutResource

const MAX_WIDTH_VARIATION: float = 0.45
const MIN_POINT_DISTANCE_SQUARED: float = 0.0001
const MIN_PROFILE_TRACK_WIDTH: float = 0.1
const MAX_PROFILE_TRACK_WIDTH: float = 100.0
const MAX_PROFILE_SHOULDER_WIDTH: float = 100.0
const MAX_PROFILE_BARRIER_DISTANCE: float = 250.0
const MAX_RACING_LINE_OFFSET: float = 50.0
const MAX_BANKING_DEGREES: float = 20.0

@export_group("Identity")
@export var track_id: StringName = &"track"
@export var display_name: String = "Track"
@export_range(1, 99, 1) var recommended_laps: int = 3

@export_group("Layout")
@export var control_points: PackedVector3Array = PackedVector3Array():
	set(value):
		if control_points == value:
			return
		control_points = value
		emit_changed()
@export_range(1, 64, 1) var samples_per_segment: int = 6:
	set(value):
		if samples_per_segment == value:
			return
		samples_per_segment = value
		emit_changed()

@export_group("Road")
@export var track_width: float = 14.0:
	set(value):
		if is_equal_approx(track_width, value):
			return
		track_width = value
		emit_changed()
@export var width_variation: float = 0.28:
	set(value):
		if is_equal_approx(width_variation, value):
			return
		width_variation = value
		emit_changed()
@export var shoulder_width: float = 10.0:
	set(value):
		if is_equal_approx(shoulder_width, value):
			return
		shoulder_width = value
		emit_changed()
@export var grass_size: Vector2 = Vector2(260.0, 190.0):
	set(value):
		if grass_size.is_equal_approx(value):
			return
		grass_size = value
		emit_changed()
@export var barrier_distance_from_road: float = 12.0:
	set(value):
		if is_equal_approx(barrier_distance_from_road, value):
			return
		barrier_distance_from_road = value
		emit_changed()

@export_group("Road Profiles")
@export var track_width_profile: PackedVector2Array = PackedVector2Array():
	set(value):
		if track_width_profile == value:
			return
		track_width_profile = value
		emit_changed()
@export var shoulder_width_profile: PackedVector2Array = PackedVector2Array():
	set(value):
		if shoulder_width_profile == value:
			return
		shoulder_width_profile = value
		emit_changed()
@export var barrier_distance_profile: PackedVector2Array = PackedVector2Array():
	set(value):
		if barrier_distance_profile == value:
			return
		barrier_distance_profile = value
		emit_changed()
@export var racing_line_offset_profile: PackedVector2Array = PackedVector2Array():
	set(value):
		if racing_line_offset_profile == value:
			return
		racing_line_offset_profile = value
		emit_changed()
@export var banking_degrees_profile: PackedVector2Array = PackedVector2Array():
	set(value):
		if banking_degrees_profile == value:
			return
		banking_degrees_profile = value
		emit_changed()

@export_group("Checkpoints")
@export var checkpoint_progresses: PackedFloat32Array = PackedFloat32Array([0.25, 0.5, 0.75]):
	set(value):
		if checkpoint_progresses == value:
			return
		checkpoint_progresses = value
		emit_changed()
@export var checkpoint_depth: float = 8.0:
	set(value):
		if is_equal_approx(checkpoint_depth, value):
			return
		checkpoint_depth = value
		emit_changed()
@export var checkpoint_height: float = 4.0:
	set(value):
		if is_equal_approx(checkpoint_height, value):
			return
		checkpoint_height = value
		emit_changed()
@export var checkpoint_width_margin: float = 1.0:
	set(value):
		if is_equal_approx(checkpoint_width_margin, value):
			return
		checkpoint_width_margin = value
		emit_changed()

@export_group("Decoration")
@export var has_stadium: bool = false:
	set(value):
		if has_stadium == value:
			return
		has_stadium = value
		emit_changed()
@export_range(1, 64, 1) var stadium_section_step: int = 8:
	set(value):
		if stadium_section_step == value:
			return
		stadium_section_step = value
		emit_changed()
@export var stadium_distance_from_barrier: float = 24.0:
	set(value):
		if is_equal_approx(stadium_distance_from_barrier, value):
			return
		stadium_distance_from_barrier = value
		emit_changed()


func is_valid() -> bool:
	return validate().is_empty()


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if track_id == &"":
		errors.append("track_id must not be empty")
	if display_name.strip_edges().is_empty():
		errors.append("display_name must not be empty")
	if recommended_laps < 1:
		errors.append("recommended_laps must be at least one")

	if control_points.size() < 4:
		errors.append("control_points must contain at least four points")
	else:
		for point_index: int in range(control_points.size()):
			var point: Vector3 = control_points[point_index]
			if not _is_finite_vector3(point):
				errors.append("control_points[%d] must be finite" % point_index)
			var next_point: Vector3 = control_points[(point_index + 1) % control_points.size()]
			if point.distance_squared_to(next_point) < MIN_POINT_DISTANCE_SQUARED:
				errors.append("control_points[%d] and the next point must not overlap" % point_index)
	if samples_per_segment < 1 or samples_per_segment > 64:
		errors.append("samples_per_segment must be within [1, 64]")

	_append_positive(errors, "track_width", track_width)
	_append_range(errors, "width_variation", width_variation, 0.0, MAX_WIDTH_VARIATION)
	_append_non_negative(errors, "shoulder_width", shoulder_width)
	if not _is_finite_vector2(grass_size) or grass_size.x <= 0.0 or grass_size.y <= 0.0:
		errors.append("grass_size components must be finite and greater than zero")
	_append_non_negative(errors, "barrier_distance_from_road", barrier_distance_from_road)
	_append_profile_range_errors(
		errors,
		"track_width_profile",
		track_width_profile,
		MIN_PROFILE_TRACK_WIDTH,
		MAX_PROFILE_TRACK_WIDTH
	)
	_append_profile_range_errors(
		errors,
		"shoulder_width_profile",
		shoulder_width_profile,
		0.0,
		MAX_PROFILE_SHOULDER_WIDTH
	)
	_append_profile_range_errors(
		errors,
		"barrier_distance_profile",
		barrier_distance_profile,
		0.0,
		MAX_PROFILE_BARRIER_DISTANCE
	)
	_append_profile_range_errors(
		errors,
		"racing_line_offset_profile",
		racing_line_offset_profile,
		-MAX_RACING_LINE_OFFSET,
		MAX_RACING_LINE_OFFSET
	)
	_append_profile_range_errors(
		errors,
		"banking_degrees_profile",
		banking_degrees_profile,
		-MAX_BANKING_DEGREES,
		MAX_BANKING_DEGREES
	)

	if not has_valid_checkpoint_sequence():
		errors.append("checkpoint_progresses must be finite, strictly increasing and within (0, 1)")
	_append_positive(errors, "checkpoint_depth", checkpoint_depth)
	_append_positive(errors, "checkpoint_height", checkpoint_height)
	_append_non_negative(errors, "checkpoint_width_margin", checkpoint_width_margin)

	if stadium_section_step < 1:
		errors.append("stadium_section_step must be at least one")
	_append_non_negative(errors, "stadium_distance_from_barrier", stadium_distance_from_barrier)
	return errors


func has_valid_checkpoint_sequence() -> bool:
	if checkpoint_progresses.is_empty():
		return false

	var previous_progress: float = 0.0
	for progress: float in checkpoint_progresses:
		if not is_finite(progress) or progress <= 0.0 or progress >= 1.0 or progress <= previous_progress:
			return false
		previous_progress = progress

	return true


func get_checkpoint_count() -> int:
	return checkpoint_progresses.size()


func get_checkpoint_gate_count() -> int:
	return get_checkpoint_count() + 1


func get_track_width_at(progress: float) -> float:
	return _sample_loop_profile(track_width_profile, progress, track_width)


func get_shoulder_width_at(progress: float) -> float:
	return _sample_loop_profile(shoulder_width_profile, progress, shoulder_width)


func get_barrier_distance_at(progress: float) -> float:
	return _sample_loop_profile(barrier_distance_profile, progress, barrier_distance_from_road)


func get_racing_line_offset_at(progress: float) -> float:
	return _sample_loop_profile(racing_line_offset_profile, progress, 0.0)


func get_banking_degrees_at(progress: float) -> float:
	return _sample_loop_profile(banking_degrees_profile, progress, 0.0)


func _sample_loop_profile(profile: PackedVector2Array, progress: float, fallback: float) -> float:
	if profile.is_empty():
		return fallback
	if profile.size() == 1:
		return profile[0].y

	var normalized_progress: float = fposmod(progress, 1.0)
	var first: Vector2 = profile[0]
	var last: Vector2 = profile[-1]
	if normalized_progress < first.x:
		return _interpolate_wrapped_profile(last, first, normalized_progress + 1.0)

	for sample_index: int in range(profile.size() - 1):
		var current: Vector2 = profile[sample_index]
		var next: Vector2 = profile[sample_index + 1]
		if normalized_progress <= next.x:
			return _interpolate_profile_pair(current, next, normalized_progress)

	return _interpolate_wrapped_profile(last, first, normalized_progress)


func _interpolate_wrapped_profile(last: Vector2, first: Vector2, progress: float) -> float:
	var wrapped_first: Vector2 = Vector2(first.x + 1.0, first.y)
	return _interpolate_profile_pair(last, wrapped_first, progress)


func _interpolate_profile_pair(current: Vector2, next: Vector2, progress: float) -> float:
	var span: float = next.x - current.x
	if span <= 0.000001:
		return current.y
	return lerpf(current.y, next.y, clampf((progress - current.x) / span, 0.0, 1.0))


func _append_profile_range_errors(
	errors: PackedStringArray,
	profile_name: String,
	profile: PackedVector2Array,
	minimum_value: float,
	maximum_value: float
) -> void:
	var previous_progress: float = -1.0
	for sample_index: int in range(profile.size()):
		var sample: Vector2 = profile[sample_index]
		if not _is_finite_vector2(sample):
			errors.append("%s[%d] must be finite" % [profile_name, sample_index])
			continue
		if sample.x < 0.0 or sample.x > 1.0:
			errors.append("%s[%d].x must be within [0, 1]" % [profile_name, sample_index])
		if sample_index > 0 and sample.x <= previous_progress:
			errors.append("%s progress values must be strictly increasing" % profile_name)
		if sample.y < minimum_value or sample.y > maximum_value:
			errors.append(
				"%s[%d].y must be within [%.3f, %.3f]"
				% [profile_name, sample_index, minimum_value, maximum_value]
			)
		previous_progress = sample.x

	if profile.size() >= 2:
		var first: Vector2 = profile[0]
		var last: Vector2 = profile[-1]
		if (
			_is_finite_vector2(first)
			and _is_finite_vector2(last)
			and is_equal_approx(first.x, 0.0)
			and is_equal_approx(last.x, 1.0)
			and not is_equal_approx(first.y, last.y)
		):
			errors.append("%s endpoint values at progress 0 and 1 must match" % profile_name)


func _append_positive(errors: PackedStringArray, property_name: String, value: float) -> void:
	if not is_finite(value) or value <= 0.0:
		errors.append("%s must be finite and greater than zero" % property_name)


func _append_non_negative(errors: PackedStringArray, property_name: String, value: float) -> void:
	if not is_finite(value) or value < 0.0:
		errors.append("%s must be finite and non-negative" % property_name)


func _append_range(
	errors: PackedStringArray,
	property_name: String,
	value: float,
	minimum: float,
	maximum: float
) -> void:
	if not is_finite(value) or value < minimum or value > maximum:
		errors.append("%s must be finite and within [%.4f, %.4f]" % [property_name, minimum, maximum])


func _is_finite_vector2(value: Vector2) -> bool:
	return is_finite(value.x) and is_finite(value.y)


func _is_finite_vector3(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)
