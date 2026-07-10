extends RefCounted
class_name SafeAreaLayout


static func calculate_fullscreen_offsets(
	viewport_size: Vector2,
	safe_area: Rect2,
	minimum_margin: float = 0.0
) -> Vector4:
	var safe_viewport_size: Vector2 = Vector2(maxf(viewport_size.x, 1.0), maxf(viewport_size.y, 1.0))
	var margin: float = maxf(minimum_margin, 0.0)
	var clamped_safe_area: Rect2 = safe_area
	if clamped_safe_area.size.x <= 0.0 or clamped_safe_area.size.y <= 0.0:
		clamped_safe_area = Rect2(Vector2.ZERO, safe_viewport_size)

	var left: float = clampf(clamped_safe_area.position.x, 0.0, safe_viewport_size.x) + margin
	var top: float = clampf(clamped_safe_area.position.y, 0.0, safe_viewport_size.y) + margin
	var safe_right: float = clampf(
		clamped_safe_area.position.x + clamped_safe_area.size.x,
		0.0,
		safe_viewport_size.x
	)
	var safe_bottom: float = clampf(
		clamped_safe_area.position.y + clamped_safe_area.size.y,
		0.0,
		safe_viewport_size.y
	)
	var right: float = maxf(safe_viewport_size.x - safe_right, 0.0) + margin
	var bottom: float = maxf(safe_viewport_size.y - safe_bottom, 0.0) + margin
	return Vector4(left, top, right, bottom)


static func apply_to_fullscreen_control(
	control: Control,
	minimum_margin: float = 0.0,
	override_safe_area: Rect2 = Rect2()
) -> void:
	if control == null or not control.is_inside_tree():
		return
	var viewport_size: Vector2 = control.get_viewport_rect().size
	var safe_area: Rect2 = override_safe_area
	if safe_area.size.x <= 0.0 or safe_area.size.y <= 0.0:
		var display_safe_area: Rect2i = DisplayServer.get_display_safe_area()
		safe_area = Rect2(display_safe_area)
	var offsets: Vector4 = calculate_fullscreen_offsets(viewport_size, safe_area, minimum_margin)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.offset_left = offsets.x
	control.offset_top = offsets.y
	control.offset_right = -offsets.z
	control.offset_bottom = -offsets.w
