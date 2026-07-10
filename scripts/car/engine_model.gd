extends RefCounted
class_name EngineModel

var idle_rpm: float = 900.0
var peak_torque_rpm: float = 4200.0
var redline_rpm: float = 6500.0
var rev_limiter_rpm: float = 6800.0
var low_rpm_torque_multiplier: float = 0.42
var mid_rpm_torque_multiplier: float = 0.82
var redline_torque_multiplier: float = 0.72
var rpm_response: float = 8.0

var _current_rpm: float = 900.0


func configure(
	target_idle_rpm: float,
	target_peak_torque_rpm: float,
	target_redline_rpm: float,
	target_rev_limiter_rpm: float,
	target_low_rpm_torque_multiplier: float,
	target_mid_rpm_torque_multiplier: float,
	target_redline_torque_multiplier: float,
	target_rpm_response: float
) -> void:
	idle_rpm = maxf(target_idle_rpm, 1.0)
	peak_torque_rpm = maxf(target_peak_torque_rpm, idle_rpm)
	redline_rpm = maxf(target_redline_rpm, peak_torque_rpm)
	rev_limiter_rpm = maxf(target_rev_limiter_rpm, redline_rpm)
	low_rpm_torque_multiplier = maxf(target_low_rpm_torque_multiplier, 0.0)
	mid_rpm_torque_multiplier = maxf(target_mid_rpm_torque_multiplier, 0.0)
	redline_torque_multiplier = maxf(target_redline_torque_multiplier, 0.0)
	rpm_response = maxf(target_rpm_response, 0.01)
	reset()


func reset() -> float:
	_current_rpm = idle_rpm
	return _current_rpm


func set_rpm(target_rpm: float) -> float:
	_current_rpm = clampf(target_rpm, idle_rpm, rev_limiter_rpm)
	return _current_rpm


func get_rpm() -> float:
	return _current_rpm


func update(
	throttle: float,
	wheel_rpm: float,
	delta: float,
	free_rev_blend: float = 1.0
) -> float:
	var safe_throttle: float = clampf(throttle, 0.0, 1.0)
	var free_rev_rpm: float = lerpf(idle_rpm, rev_limiter_rpm, safe_throttle)
	var coupled_rpm: float = maxf(wheel_rpm, idle_rpm)
	var uncoupled_target_rpm: float = maxf(coupled_rpm, free_rev_rpm)
	var target_rpm: float = lerpf(
		coupled_rpm,
		uncoupled_target_rpm,
		clampf(free_rev_blend, 0.0, 1.0)
	)
	var rpm_blend: float = 1.0 - exp(-rpm_response * maxf(delta, 0.0))

	_current_rpm = lerpf(_current_rpm, target_rpm, rpm_blend)
	_current_rpm = clampf(_current_rpm, idle_rpm, rev_limiter_rpm)
	return _current_rpm


func get_torque_multiplier() -> float:
	var rpm_range: float = maxf(redline_rpm - idle_rpm, 1.0)
	var normalized_rpm: float = clampf((_current_rpm - idle_rpm) / rpm_range, 0.0, 1.0)
	var peak_rpm_ratio: float = clampf((peak_torque_rpm - idle_rpm) / rpm_range, 0.01, 0.99)

	if normalized_rpm <= peak_rpm_ratio:
		var low_rpm_ratio: float = 0.34
		if normalized_rpm <= low_rpm_ratio:
			var low_blend: float = _smoothstep(normalized_rpm / low_rpm_ratio)
			return lerpf(low_rpm_torque_multiplier, mid_rpm_torque_multiplier, low_blend)
		var peak_blend: float = _smoothstep((normalized_rpm - low_rpm_ratio) / (peak_rpm_ratio - low_rpm_ratio))
		return lerpf(mid_rpm_torque_multiplier, 1.0, peak_blend)

	var high_rpm_ratio: float = (normalized_rpm - peak_rpm_ratio) / (1.0 - peak_rpm_ratio)
	var high_blend: float = _smoothstep(high_rpm_ratio)
	return lerpf(1.0, redline_torque_multiplier, high_blend)


func get_rev_limiter_multiplier() -> float:
	if _current_rpm < redline_rpm:
		return 1.0
	var limiter_range: float = rev_limiter_rpm - redline_rpm
	if limiter_range <= 0.0:
		return 0.0
	return 1.0 - clampf((_current_rpm - redline_rpm) / limiter_range, 0.0, 1.0)


func _smoothstep(value: float) -> float:
	var clamped_value: float = clampf(value, 0.0, 1.0)
	return clamped_value * clamped_value * (3.0 - 2.0 * clamped_value)
