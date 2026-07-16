extends Resource
class_name TrafficRiderPowertrainDefinition

@export_group("Architecture")
@export var planetary_automatic_enabled: bool = false
@export var on_demand_awd_enabled: bool = false

@export_group("Planetary automatic shift phases")
@export var torque_reduction_duration_s: float = 0.0
@export var handover_duration_s: float = 0.0
@export var inertia_duration_s: float = 0.0
@export var reapply_duration_s: float = 0.0
@export_range(0.0, 1.0, 0.01) var minimum_torque_factor: float = 0.0
@export_range(0.0, 1.0, 0.01) var handover_torque_factor: float = 0.0
@export_range(0.0, 1.0, 0.01) var inertia_torque_factor: float = 0.0
@export_range(1, 8, 1) var maximum_skip_gears: int = 1

@export_group("Torque converter and lock-up")
@export var stall_torque_multiplier: float = 0.0
@export_range(0.0, 1.0, 0.01) var coupling_speed_ratio: float = 0.0
@export var lockup_minimum_speed_mps: float = 0.0
@export var lockup_minimum_gear: int = 0
@export_range(0.0, 1.0, 0.01) var lockup_maximum_throttle: float = 0.0
@export var lockup_engage_rate_per_s: float = 0.0
@export var lockup_release_rate_per_s: float = 0.0
@export var commanded_lockup_slip_rpm: float = 0.0

@export_group("On-demand AWD command")
@export_range(0.0, 1.0, 0.01) var base_front_torque_fraction: float = 0.0
@export_range(0.0, 1.0, 0.01) var maximum_front_torque_fraction: float = 0.0
@export_range(0.0, 1.0, 0.01) var launch_clutch_command: float = 0.0
@export var throttle_command_gain: float = 0.0
@export var slip_command_gain: float = 0.0
@export var stability_command_gain: float = 0.0
@export var clutch_engage_rate_per_s: float = 0.0
@export var clutch_release_rate_per_s: float = 0.0
@export var maximum_transfer_clutch_capacity_nm: float = 0.0
@export var high_speed_release_start_mps: float = 0.0
@export var high_speed_release_end_mps: float = 0.0

@export_group("On-demand AWD thermal model")
@export var transfer_clutch_thermal_mass_j_per_c: float = 0.0
@export var transfer_clutch_cooling_w_per_c: float = 0.0
@export var transfer_clutch_derate_start_c: float = 0.0
@export var transfer_clutch_shutdown_c: float = 0.0


func has_advanced_architecture() -> bool:
	return planetary_automatic_enabled or on_demand_awd_enabled


func validate_for(config: CarDriveConfig) -> PackedStringArray:
	var errors := PackedStringArray()
	if config == null:
		errors.append("Traffic Rider powertrain definition requires a drive configuration")
		return errors
	if planetary_automatic_enabled:
		_validate_planetary_automatic(config, errors)
	if on_demand_awd_enabled:
		_validate_on_demand_awd(config, errors)
	return errors


func _validate_planetary_automatic(config: CarDriveConfig, errors: PackedStringArray) -> void:
	if not config.is_torque_converter_automatic():
		errors.append("planetary automatic requires a non-SMG torque-converter automatic configuration")
	if config.gear_ratios.size() < 2:
		errors.append("planetary automatic requires at least two exact forward ratios")
	_append_positive(errors, "torque_reduction_duration_s", torque_reduction_duration_s)
	_append_positive(errors, "handover_duration_s", handover_duration_s)
	_append_positive(errors, "inertia_duration_s", inertia_duration_s)
	_append_positive(errors, "reapply_duration_s", reapply_duration_s)
	_append_range(errors, "minimum_torque_factor", minimum_torque_factor, 0.01, 1.0)
	_append_range(errors, "handover_torque_factor", handover_torque_factor, minimum_torque_factor, 1.0)
	_append_range(errors, "inertia_torque_factor", inertia_torque_factor, handover_torque_factor, 1.0)
	_append_range(errors, "stall_torque_multiplier", stall_torque_multiplier, 1.0, 4.0)
	_append_range(errors, "coupling_speed_ratio", coupling_speed_ratio, 0.05, 1.0)
	_append_non_negative(errors, "lockup_minimum_speed_mps", lockup_minimum_speed_mps)
	if lockup_minimum_gear < 1 or lockup_minimum_gear > config.gear_ratios.size():
		errors.append("lockup_minimum_gear must reference an exact forward gear")
	_append_range(errors, "lockup_maximum_throttle", lockup_maximum_throttle, 0.0, 1.0)
	_append_positive(errors, "lockup_engage_rate_per_s", lockup_engage_rate_per_s)
	_append_positive(errors, "lockup_release_rate_per_s", lockup_release_rate_per_s)
	_append_non_negative(errors, "commanded_lockup_slip_rpm", commanded_lockup_slip_rpm)
	if maximum_skip_gears < 1 or maximum_skip_gears >= config.gear_ratios.size():
		errors.append("maximum_skip_gears must be within the exact forward gear count")


func _validate_on_demand_awd(config: CarDriveConfig, errors: PackedStringArray) -> void:
	if not config.is_all_wheel_drive():
		errors.append("on-demand AWD requires an AWD drive layout")
	_append_range(errors, "base_front_torque_fraction", base_front_torque_fraction, 0.0, 1.0)
	_append_range(errors, "maximum_front_torque_fraction", maximum_front_torque_fraction, base_front_torque_fraction, 1.0)
	if maximum_front_torque_fraction <= base_front_torque_fraction:
		errors.append("maximum_front_torque_fraction must exceed the base fraction")
	_append_range(errors, "launch_clutch_command", launch_clutch_command, 0.0, 1.0)
	_append_non_negative(errors, "throttle_command_gain", throttle_command_gain)
	_append_non_negative(errors, "slip_command_gain", slip_command_gain)
	_append_non_negative(errors, "stability_command_gain", stability_command_gain)
	_append_positive(errors, "clutch_engage_rate_per_s", clutch_engage_rate_per_s)
	_append_positive(errors, "clutch_release_rate_per_s", clutch_release_rate_per_s)
	_append_positive(errors, "maximum_transfer_clutch_capacity_nm", maximum_transfer_clutch_capacity_nm)
	_append_non_negative(errors, "high_speed_release_start_mps", high_speed_release_start_mps)
	if high_speed_release_end_mps <= high_speed_release_start_mps:
		errors.append("high_speed_release_end_mps must exceed the release start speed")
	_append_positive(errors, "transfer_clutch_thermal_mass_j_per_c", transfer_clutch_thermal_mass_j_per_c)
	_append_non_negative(errors, "transfer_clutch_cooling_w_per_c", transfer_clutch_cooling_w_per_c)
	_append_positive(errors, "transfer_clutch_derate_start_c", transfer_clutch_derate_start_c)
	if transfer_clutch_shutdown_c <= transfer_clutch_derate_start_c:
		errors.append("transfer_clutch_shutdown_c must exceed the derate temperature")


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
