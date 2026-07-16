extends Resource
class_name TrafficRiderInlineEngineAudioProfile

enum CombustionType {
	PETROL_PORT_INJECTION,
	PETROL_DIRECT_INJECTION,
	DIESEL_COMMON_RAIL,
}

enum AspirationType {
	NATURALLY_ASPIRATED,
	SINGLE_TURBO,
	SEQUENTIAL_TWIN_TURBO,
	VARIABLE_GEOMETRY_TURBO,
}

@export_group("Identity")
@export var engine_family_id: StringName = &""
@export var display_name: String = ""
@export_enum("3", "4", "6") var cylinder_count: int = 4
@export var firing_order := PackedInt32Array()
@export var collector_group_by_cylinder := PackedInt32Array()
@export var combustion_type: int = CombustionType.PETROL_DIRECT_INJECTION
@export var aspiration_type: int = AspirationType.NATURALLY_ASPIRATED

@export_group("Operating range")
@export var idle_rpm: float = 0.0
@export var redline_rpm: float = 0.0
@export var limiter_period_s: float = 0.0
@export_range(0.0, 1.0, 0.01) var limiter_cut_fraction: float = 0.0
@export_range(0.0, 1.0, 0.01) var limiter_residual_combustion: float = 0.0
@export_range(0.0, 1.0, 0.01) var idle_irregularity: float = 0.0

@export_group("Combustion and gas paths")
@export_range(0.0, 1.0, 0.01) var combustion_sharpness: float = 0.0
@export_range(0.0, 2.0, 0.01) var combustion_level: float = 0.0
@export_range(0.0, 2.0, 0.01) var intake_level: float = 0.0
@export_range(0.0, 2.0, 0.01) var exhaust_level: float = 0.0
@export_range(0.0, 2.0, 0.01) var mechanical_level: float = 0.0
@export_range(0.0, 2.0, 0.01) var injector_level: float = 0.0
@export_range(0.0, 2.0, 0.01) var diesel_clatter_level: float = 0.0
@export var intake_resonance_hz: float = 0.0
@export var exhaust_resonance_hz: float = 0.0
@export var mechanical_order: float = 0.0
@export_range(0.0, 1.0, 0.01) var collector_separation: float = 0.0

@export_group("Forced induction")
@export var turbo_spool_rate_per_s: float = 0.0
@export var turbo_release_rate_per_s: float = 0.0
@export var turbo_whine_base_hz: float = 0.0
@export var turbo_whine_range_hz: float = 0.0
@export_range(0.0, 2.0, 0.01) var turbo_whine_level: float = 0.0
@export_range(0.0, 2.0, 0.01) var turbine_level: float = 0.0
@export_range(0.0, 2.0, 0.01) var wastegate_level: float = 0.0
@export_range(0.0, 2.0, 0.01) var release_level: float = 0.0
@export_range(0.0, 1.0, 0.01) var second_stage_threshold: float = 0.0
@export_range(0.0, 1.0, 0.01) var second_stage_level: float = 0.0

@export_group("Level contract")
@export_range(0.01, 1.0, 0.01) var synthesis_gain: float = 0.25
@export_range(0.01, 0.99, 0.01) var peak_limit: float = 0.92


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if engine_family_id == &"":
		errors.append("engine_family_id must not be empty")
	if display_name.strip_edges().is_empty():
		errors.append("display_name must not be empty")
	if cylinder_count not in [3, 4, 6]:
		errors.append("cylinder_count must be 3, 4 or 6")
	_validate_firing_order(errors)
	_validate_collectors(errors)
	if combustion_type < CombustionType.PETROL_PORT_INJECTION or combustion_type > CombustionType.DIESEL_COMMON_RAIL:
		errors.append("combustion_type is invalid")
	if aspiration_type < AspirationType.NATURALLY_ASPIRATED or aspiration_type > AspirationType.VARIABLE_GEOMETRY_TURBO:
		errors.append("aspiration_type is invalid")
	_append_positive(errors, "idle_rpm", idle_rpm)
	if redline_rpm <= idle_rpm:
		errors.append("redline_rpm must exceed idle_rpm")
	_append_positive(errors, "limiter_period_s", limiter_period_s)
	_append_range(errors, "limiter_cut_fraction", limiter_cut_fraction, 0.0, 1.0)
	_append_range(errors, "limiter_residual_combustion", limiter_residual_combustion, 0.0, 1.0)
	_append_range(errors, "combustion_sharpness", combustion_sharpness, 0.01, 1.0)
	_append_positive(errors, "combustion_level", combustion_level)
	_append_positive(errors, "intake_resonance_hz", intake_resonance_hz)
	_append_positive(errors, "exhaust_resonance_hz", exhaust_resonance_hz)
	_append_positive(errors, "mechanical_order", mechanical_order)
	if aspiration_type != AspirationType.NATURALLY_ASPIRATED:
		_validate_forced_induction(errors)
	return errors


func is_diesel() -> bool:
	return combustion_type == CombustionType.DIESEL_COMMON_RAIL


func is_turbocharged() -> bool:
	return aspiration_type != AspirationType.NATURALLY_ASPIRATED


func get_event_frequency_hz(rpm: float) -> float:
	return maxf(rpm, 0.0) / 60.0 * float(cylinder_count) * 0.5


func _validate_firing_order(errors: PackedStringArray) -> void:
	if firing_order.size() != cylinder_count:
		errors.append("firing_order size must match cylinder_count")
		return
	var seen: Dictionary = {}
	for cylinder_number: int in firing_order:
		if cylinder_number < 1 or cylinder_number > cylinder_count:
			errors.append("firing_order contains a cylinder outside the valid range")
			return
		if seen.has(cylinder_number):
			errors.append("firing_order must be a permutation without duplicates")
			return
		seen[cylinder_number] = true


func _validate_collectors(errors: PackedStringArray) -> void:
	if collector_group_by_cylinder.size() != cylinder_count:
		errors.append("collector_group_by_cylinder size must match cylinder_count")
		return
	for collector_index: int in collector_group_by_cylinder:
		if collector_index < 0 or collector_index > 1:
			errors.append("collector_group_by_cylinder supports collector groups 0 and 1")
			return


func _validate_forced_induction(errors: PackedStringArray) -> void:
	_append_positive(errors, "turbo_spool_rate_per_s", turbo_spool_rate_per_s)
	_append_positive(errors, "turbo_release_rate_per_s", turbo_release_rate_per_s)
	_append_positive(errors, "turbo_whine_base_hz", turbo_whine_base_hz)
	_append_non_negative(errors, "turbo_whine_range_hz", turbo_whine_range_hz)
	if turbo_whine_level <= 0.0 and turbine_level <= 0.0:
		errors.append("turbocharged profile requires compressor or turbine audio")
	if aspiration_type == AspirationType.SEQUENTIAL_TWIN_TURBO:
		_append_range(errors, "second_stage_threshold", second_stage_threshold, 0.01, 0.99)
		_append_positive(errors, "second_stage_level", second_stage_level)


func _append_positive(errors: PackedStringArray, field_name: String, value: float) -> void:
	if value <= 0.0:
		errors.append("%s must be positive" % field_name)


func _append_non_negative(errors: PackedStringArray, field_name: String, value: float) -> void:
	if value < 0.0:
		errors.append("%s must not be negative" % field_name)


func _append_range(
	errors: PackedStringArray,
	field_name: String,
	value: float,
	minimum: float,
	maximum: float
) -> void:
	if value < minimum or value > maximum:
		errors.append("%s must be in [%.3f, %.3f]" % [field_name, minimum, maximum])
