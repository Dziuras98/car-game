extends Control
class_name TachometerGauge

@export var min_rpm: float = 0.0
@export var max_rpm: float = 7000.0
@export var redline_rpm: float = 6500.0
@export var major_tick_rpm: float = 1000.0
@export var minor_tick_rpm: float = 500.0
@export var start_angle_degrees: float = 140.0
@export var end_angle_degrees: float = 400.0

var _rpm: float = 0.0


func configure_range(maximum_rpm: float, redline: float) -> void:
	max_rpm = maxf(maximum_rpm, min_rpm + major_tick_rpm)
	redline_rpm = clampf(redline, min_rpm, max_rpm)
	_rpm = clampf(_rpm, min_rpm, max_rpm)
	queue_redraw()


func set_rpm(value: float) -> void:
	_rpm = clampf(value, min_rpm, max_rpm)
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.43
	var start_angle: float = deg_to_rad(start_angle_degrees)
	var end_angle: float = deg_to_rad(end_angle_degrees)

	draw_circle(center, radius + 10.0, Color(0.035, 0.04, 0.05, 0.9))
	draw_arc(center, radius, start_angle, end_angle, 48, Color(0.35, 0.42, 0.48, 1), 4.0)
	_draw_redline(center, radius, start_angle, end_angle)
	_draw_ticks(center, radius, start_angle, end_angle)
	_draw_numbers(center, radius, start_angle, end_angle)
	_draw_needle(center, radius, start_angle, end_angle)
	draw_circle(center, 6.0, Color(0.95, 0.95, 0.95, 1))


func _draw_redline(center: Vector2, radius: float, start_angle: float, end_angle: float) -> void:
	var redline_angle: float = _rpm_to_angle(redline_rpm, start_angle, end_angle)

	draw_arc(center, radius, redline_angle, end_angle, 16, Color(0.95, 0.12, 0.08, 1), 5.0)


func _draw_ticks(center: Vector2, radius: float, start_angle: float, end_angle: float) -> void:
	var minor_value: float = min_rpm
	while minor_value <= max_rpm + 0.1:
		if not _is_major_tick(minor_value):
			_draw_tick(center, radius, start_angle, end_angle, minor_value, 6.0, 1.0)
		minor_value += minor_tick_rpm

	var major_value: float = min_rpm
	while major_value <= max_rpm + 0.1:
		_draw_tick(center, radius, start_angle, end_angle, major_value, 12.0, 2.0)
		major_value += major_tick_rpm

	if not _is_major_tick(max_rpm):
		_draw_tick(center, radius, start_angle, end_angle, max_rpm, 12.0, 2.0)


func _draw_numbers(center: Vector2, radius: float, start_angle: float, end_angle: float) -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 14

	var label_value: float = min_rpm
	while label_value <= max_rpm + 0.1:
		_draw_number(center, radius, start_angle, end_angle, label_value, font, font_size)
		label_value += major_tick_rpm

	if not _is_major_tick(max_rpm):
		_draw_number(center, radius, start_angle, end_angle, max_rpm, font, font_size)


func _draw_needle(center: Vector2, radius: float, start_angle: float, end_angle: float) -> void:
	var needle_angle: float = _rpm_to_angle(_rpm, start_angle, end_angle)
	var needle_direction: Vector2 = Vector2(cos(needle_angle), sin(needle_angle))
	var needle_end: Vector2 = center + needle_direction * (radius - 18.0)

	draw_line(center, needle_end, Color(0.1, 0.85, 1.0, 1), 4.0)


func _draw_tick(
	center: Vector2,
	radius: float,
	start_angle: float,
	end_angle: float,
	rpm_value: float,
	length: float,
	width: float
) -> void:
	var angle: float = _rpm_to_angle(rpm_value, start_angle, end_angle)
	var tick_direction: Vector2 = Vector2(cos(angle), sin(angle))
	var tick_start: Vector2 = center + tick_direction * (radius - length)
	var tick_end: Vector2 = center + tick_direction * (radius + 2.0)
	var tick_color: Color = Color(0.95, 0.95, 0.95, 1)

	if rpm_value >= redline_rpm:
		tick_color = Color(1.0, 0.18, 0.12, 1)

	draw_line(tick_start, tick_end, tick_color, width)


func _draw_number(
	center: Vector2,
	radius: float,
	start_angle: float,
	end_angle: float,
	rpm_value: float,
	font: Font,
	font_size: int
) -> void:
	var angle: float = _rpm_to_angle(rpm_value, start_angle, end_angle)
	var label_direction: Vector2 = Vector2(cos(angle), sin(angle))
	var label_text: String = _format_rpm_label(rpm_value)
	var label_size: Vector2 = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var label_position: Vector2 = center + label_direction * (radius - 28.0) - label_size * 0.5
	var label_color: Color = Color(0.82, 0.88, 0.92, 1)

	if rpm_value >= redline_rpm:
		label_color = Color(1.0, 0.22, 0.16, 1)

	draw_string(font, label_position, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)


func _rpm_to_angle(value: float, start_angle: float, end_angle: float) -> float:
	return lerpf(start_angle, end_angle, _rpm_to_ratio(value))


func _rpm_to_ratio(value: float) -> float:
	if max_rpm <= min_rpm:
		return 0.0

	return clampf((value - min_rpm) / (max_rpm - min_rpm), 0.0, 1.0)


func _is_major_tick(value: float) -> bool:
	if major_tick_rpm <= 0.0:
		return false

	var nearest_major_tick: float = roundf((value - min_rpm) / major_tick_rpm) * major_tick_rpm + min_rpm
	return absf(value - nearest_major_tick) <= 0.1


func _format_rpm_label(value: float) -> String:
	var thousands: float = value / 1000.0
	if absf(thousands - roundf(thousands)) <= 0.05:
		return str(roundi(thousands))

	return str(snappedf(thousands, 0.1))
