extends Resource
class_name EngineTorqueCurve


@export var rpm_points: PackedFloat32Array = PackedFloat32Array([800.0, 6500.0])
@export var torque_multipliers: PackedFloat32Array = PackedFloat32Array([0.5, 0.75])


func sample(rpm: float) -> float:
	if rpm_points.is_empty() or torque_multipliers.is_empty():
		return 0.0
	if rpm_points.size() != torque_multipliers.size():
		return 0.0
	var safe_rpm: float = rpm if is_finite(rpm) else rpm_points[0]
	if safe_rpm <= rpm_points[0]:
		return maxf(torque_multipliers[0], 0.0)
	var last_index: int = rpm_points.size() - 1
	if safe_rpm >= rpm_points[last_index]:
		return maxf(torque_multipliers[last_index], 0.0)
	for index: int in range(1, rpm_points.size()):
		if safe_rpm > rpm_points[index]:
			continue
		var lower_rpm: float = rpm_points[index - 1]
		var upper_rpm: float = rpm_points[index]
		var span: float = maxf(upper_rpm - lower_rpm, 0.001)
		var blend: float = clampf((safe_rpm - lower_rpm) / span, 0.0, 1.0)
		return lerpf(
			maxf(torque_multipliers[index - 1], 0.0),
			maxf(torque_multipliers[index], 0.0),
			blend
		)
	return maxf(torque_multipliers[last_index], 0.0)


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if rpm_points.size() < 2:
		errors.append("rpm_points must contain at least two samples")
	if rpm_points.size() != torque_multipliers.size():
		errors.append("rpm_points and torque_multipliers must have the same size")
	var comparable_count: int = mini(rpm_points.size(), torque_multipliers.size())
	for index: int in comparable_count:
		var sample_rpm: float = rpm_points[index]
		var multiplier: float = torque_multipliers[index]
		if not is_finite(sample_rpm) or sample_rpm < 0.0:
			errors.append("rpm_points[%d] must be finite and non-negative" % index)
		if index > 0 and sample_rpm <= rpm_points[index - 1]:
			errors.append("rpm_points must be strictly ascending")
		if not is_finite(multiplier) or multiplier < 0.0:
			errors.append("torque_multipliers[%d] must be finite and non-negative" % index)
	return errors
