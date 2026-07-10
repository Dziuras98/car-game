extends Resource
class_name TrackLayoutResource

const MAX_WIDTH_VARIATION: float = 0.45
const MIN_POINT_DISTANCE_SQUARED: float = 0.0001

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
