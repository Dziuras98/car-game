extends RefCounted
class_name BmwF32EngineCurveFactory


static func create(engine: Dictionary) -> EngineTorqueCurve:
	var peak_torque: float = _number(engine, "torque_nm", 200.0)
	var power_kw: float = _number(engine, "power_kw", 0.0)
	if power_kw <= 0.0:
		power_kw = _number(engine, "power_hp", 100.0) * 0.745699872
	var fuel: String = str(engine.get("fuel", "petrol"))
	var aspiration: String = str(engine.get("aspiration", "turbo"))
	var cylinders: int = int(_number(engine, "cylinders", 4.0))
	var idle_rpm: float = 760.0 if fuel == "diesel" else 700.0
	var redline_rpm: float = 5000.0 if fuel == "diesel" else 7000.0
	var torque_start: float = _range_start(str(engine.get("torque_rpm", "")), 1500.0 if fuel == "diesel" else 1250.0)
	var torque_end: float = _range_end(str(engine.get("torque_rpm", "")), 3000.0 if fuel == "diesel" else 4500.0)
	if aspiration == "twin_turbo":
		torque_start -= 150.0
		torque_end += 250.0
	var power_peak: float = _range_mid(str(engine.get("power_rpm", "")), 4000.0 if fuel == "diesel" else 6000.0)
	power_peak = clampf(power_peak, torque_end + 250.0, redline_rpm - 100.0)
	var power_peak_torque: float = power_kw * 9549.296596 / maxf(power_peak, 1.0)
	var power_multiplier: float = clampf(power_peak_torque / maxf(peak_torque, 1.0), 0.42, 1.0)
	var spool_rpm: float = maxf(idle_rpm + 250.0, torque_start - (450.0 if fuel == "petrol" else 350.0))
	var plateau_mid: float = (torque_start + torque_end) * 0.5
	var redline_multiplier: float = clampf(power_multiplier * (0.78 if fuel == "petrol" else 0.67), 0.28, 0.80)
	if cylinders == 3:
		redline_multiplier *= 0.94

	var anchors: Dictionary = {
		idle_rpm: 0.56 if fuel == "petrol" else 0.70,
		spool_rpm: 0.76 if fuel == "petrol" else 0.84,
		torque_start: 1.0,
		plateau_mid: 1.0,
		torque_end: 1.0,
		power_peak: power_multiplier,
		redline_rpm: redline_multiplier,
	}
	var ordered_rpm: Array[float] = []
	for rpm_value: Variant in anchors.keys():
		ordered_rpm.append(float(rpm_value))
	ordered_rpm.sort()
	var rpm_points := PackedFloat32Array()
	var multipliers := PackedFloat32Array()
	for rpm_value: float in ordered_rpm:
		if not rpm_points.is_empty() and rpm_value <= rpm_points[-1]:
			continue
		rpm_points.append(rpm_value)
		multipliers.append(float(anchors[rpm_value]))
	var curve := EngineTorqueCurve.new()
	curve.resource_name = "BMW F32 %s evidence-constrained torque curve" % str(engine.get("engine_key", "engine"))
	curve.rpm_points = rpm_points
	curve.torque_multipliers = multipliers
	return curve


static func get_idle_rpm(engine: Dictionary) -> float:
	return 760.0 if str(engine.get("fuel", "petrol")) == "diesel" else 700.0


static func get_redline_rpm(engine: Dictionary) -> float:
	return 5000.0 if str(engine.get("fuel", "petrol")) == "diesel" else 7000.0


static func get_power_peak_rpm(engine: Dictionary) -> float:
	var fuel: String = str(engine.get("fuel", "petrol"))
	var redline: float = get_redline_rpm(engine)
	var torque_end: float = _range_end(str(engine.get("torque_rpm", "")), 3000.0 if fuel == "diesel" else 4500.0)
	return clampf(_range_mid(str(engine.get("power_rpm", "")), 4000.0 if fuel == "diesel" else 6000.0), torque_end + 250.0, redline - 100.0)


static func get_peak_torque_rpm(engine: Dictionary) -> float:
	return _range_start(str(engine.get("torque_rpm", "")), 1500.0 if str(engine.get("fuel", "petrol")) == "diesel" else 1250.0)


static func _range_start(text: String, fallback: float) -> float:
	var values: PackedStringArray = _range_values(text)
	return values[0].to_float() if not values.is_empty() and values[0].is_valid_float() else fallback


static func _range_end(text: String, fallback: float) -> float:
	var values: PackedStringArray = _range_values(text)
	if values.size() >= 2 and values[1].is_valid_float():
		return values[1].to_float()
	if values.size() == 1 and values[0].is_valid_float():
		return values[0].to_float()
	return fallback


static func _range_mid(text: String, fallback: float) -> float:
	var start: float = _range_start(text, fallback)
	var end: float = _range_end(text, start)
	return (start + end) * 0.5


static func _range_values(text: String) -> PackedStringArray:
	var normalized: String = text.replace("–", "-").replace("—", "-").strip_edges()
	if normalized.is_empty():
		return PackedStringArray()
	return normalized.split("-", false)


static func _number(row: Dictionary, field: String, fallback: float) -> float:
	var text: String = str(row.get(field, "")).strip_edges()
	return text.to_float() if text.is_valid_float() else fallback
