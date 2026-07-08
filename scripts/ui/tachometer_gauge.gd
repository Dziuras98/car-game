extends Control
class_name TachometerGauge

@export var min_rpm: float = 0.0
@export var max_rpm: float = 7000.0
@export var redline_rpm: float = 6500.0
@export var start_angle_degrees: float = 140.0
@export var end_angle_degrees: float = 400.0

var _rpm: float = 0.0


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
	var redline_ratio: float = _rpm_to_ratio(redline_rpm)
	var redline_angle: float = lerpf(start_angle, end_angle, redline_ratio)

	draw_arc(center, radius, redline_angle, end_angle, 16, Color(0.95, 0.12, 0.08, 1), 5.0)


func _draw_ticks(center: Vector2, radius: float, start_angle: float, end_angle: float) -> void:
	var tick_count: int = 7
	for tick_index in range(tick_count + 1):
		var ratio: float = float(tick_index) / float(tick_count)
		var angle: float = lerpf(start_angle, end_angle, ratio)
		var tick_direction: Vector2 = Vector2(cos(angle), sin(angle))
		var tick_start: Vector2 = center + tick_direction * (radius - 10.0)
		var tick_end: Vector2 = center + tick_direction * (radius + 2.0)
		var tick_color: Color = Color(0.95, 0.95, 0.95, 1)

		if ratio >= _rpm_to_ratio(redline_rpm):
			tick_color = Color(1.0, 0.18, 0.12, 1)

		draw_line(tick_start, tick_end, tick_color, 2.0)


func _draw_numbers(center: Vector2, radius: float, start_angle: float, end_angle: float) -> void:
	var label_count: int = roundi(max_rpm / 1000.0)
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 14

	for label_index in range(label_count + 1):
		var rpm_value: float = float(label_index) * 1000.0
		var ratio: float = _rpm_to_ratio(rpm_value)
		var angle: float = lerpf(start_angle, end_angle, ratio)
		var label_direction: Vector2 = Vector2(cos(angle), sin(angle))
		var label_text: String = str(label_index)
		var label_size: Vector2 = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var label_position: Vector2 = center + label_direction * (radius - 28.0) - label_size * 0.5
		var label_color: Color = Color(0.82, 0.88, 0.92, 1)

		if rpm_value >= redline_rpm:
			label_color = Color(1.0, 0.22, 0.16, 1)

		draw_string(font, label_position, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)


func _draw_needle(center: Vector2, radius: float, start_angle: float, end_angle: float) -> void:
	var rpm_ratio: float = _rpm_to_ratio(_rpm)
	var needle_angle: float = lerpf(start_angle, end_angle, rpm_ratio)
	var needle_direction: Vector2 = Vector2(cos(needle_angle), sin(needle_angle))
	var needle_end: Vector2 = center + needle_direction * (radius - 18.0)

	draw_line(center, needle_end, Color(0.1, 0.85, 1.0, 1), 4.0)


func _rpm_to_ratio(value: float) -> float:
	if max_rpm <= min_rpm:
		return 0.0

	return clampf((value - min_rpm) / (max_rpm - min_rpm), 0.0, 1.0)
