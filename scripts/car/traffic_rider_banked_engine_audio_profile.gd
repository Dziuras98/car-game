extends Resource
class_name TrafficRiderBankedEngineAudioProfile

enum CrankArchitecture {
	EVEN_FIRE_SPLIT_PIN_V6,
	CROSS_PLANE_V8,
	FLAT_PLANE_V8,
}

enum CombustionType {
	PETROL_PORT_INJECTION,
	PETROL_DIRECT_INJECTION,
	DIESEL_COMMON_RAIL,
}

@export_group("Identity")
@export var engine_family_id: StringName = &""
@export var display_name: String = ""

@export_group("Physical architecture")
@export_range(4, 12, 1) var cylinder_count: int = 8
@export_range(30.0, 180.0, 0.1) var bank_angle_degrees: float = 90.0
@export var crank_architecture: int = CrankArchitecture.CROSS_PLANE_V8
@export var firing_order := PackedInt32Array([1, 8, 7, 2, 6, 5, 4, 3])
@export var cylinder_bank_by_number := PackedInt32Array([0, 1, 0, 1, 0, 1, 0, 1])
@export var collector_group_by_cylinder := PackedInt32Array([0, 1, 0, 1, 0, 1, 0, 1])
@export var pushrod_valvetrain: bool = true
@export var combustion_type: int = CombustionType.PETROL_DIRECT_INJECTION
@export_range(500.0, 1200.0, 1.0) var idle_rpm: float = 625.0
@export_range(3500.0, 9000.0, 10.0) var redline_rpm: float = 6000.0
@export_range(1.0, 10.0, 0.01) var displacement_l: float = 5.3
@export_range(70.0, 120.0, 0.1) var bore_mm: float = 96.0
@export_range(70.0, 120.0, 0.1) var stroke_mm: float = 92.0

@export_group("Cylinder deactivation")
@export var cylinder_deactivation_enabled: bool = false
@export var deactivated_cylinders := PackedInt32Array()
@export_range(0.0, 1.0, 0.01) var deactivation_enter_load: float = 0.22
@export_range(0.0, 1.0, 0.01) var deactivation_exit_load: float = 0.34
@export_range(0.1, 10.0, 0.1) var deactivation_transition_rate_per_s: float = 3.5
@export_range(500.0, 5000.0, 10.0) var deactivation_min_rpm: float = 1000.0
@export_range(500.0, 5000.0, 10.0) var deactivation_max_rpm: float = 3000.0

@export_group("Source levels")
@export_range(0.0, 2.0, 0.01) var combustion_level: float = 0.72
@export_range(0.0, 1.0, 0.01) var combustion_sharpness: float = 0.42
@export_range(0.0, 2.0, 0.01) var intake_level: float = 0.34
@export_range(0.0, 2.0, 0.01) var exhaust_level: float = 0.72
@export_range(0.0, 2.0, 0.01) var valvetrain_level: float = 0.20
@export_range(0.0, 2.0, 0.01) var injector_level: float = 0.18
@export_range(0.0, 2.0, 0.01) var crank_level: float = 0.16
@export_range(0.0, 2.0, 0.01) var afm_transition_level: float = 0.14
@export_range(20.0, 400.0, 1.0) var intake_resonance_hz: float = 82.0
@export_range(20.0, 300.0, 1.0) var exhaust_resonance_hz: float = 57.0
@export_range(0.0, 1.0, 0.01) var bank_separation: float = 0.48
@export_range(0.01, 1.0, 0.01) var synthesis_gain: float = 0.20
@export_range(0.1, 0.99, 0.01) var peak_limit: float = 0.91

@export_group("Limiter")
@export_range(0.02, 0.20, 0.001) var limiter_period_s: float = 0.060
@export_range(0.0, 1.0, 0.01) var limiter_cut_fraction: float = 0.44
@export_range(0.0, 1.0, 0.01) var limiter_residual_combustion: float = 0.16


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if engine_family_id == &"": errors.append("engine_family_id must not be empty")
	if display_name.strip_edges().is_empty(): errors.append("display_name must not be empty")
	if cylinder_count != 6 and cylinder_count != 8:
		errors.append("banked engine profile currently supports six or eight cylinders")
	if firing_order.size() != cylinder_count:
		errors.append("firing_order size must equal cylinder_count")
	if cylinder_bank_by_number.size() != cylinder_count:
		errors.append("cylinder_bank_by_number size must equal cylinder_count")
	if collector_group_by_cylinder.size() != cylinder_count:
		errors.append("collector_group_by_cylinder size must equal cylinder_count")
	var seen: Dictionary = {}
	for cylinder: int in firing_order:
		if cylinder < 1 or cylinder > cylinder_count or seen.has(cylinder):
			errors.append("firing_order must contain every cylinder exactly once")
			break
		seen[cylinder] = true
	for bank: int in cylinder_bank_by_number:
		if bank < 0 or bank > 1:
			errors.append("cylinder_bank_by_number must contain only bank 0/1")
			break
	for cylinder: int in deactivated_cylinders:
		if cylinder < 1 or cylinder > cylinder_count:
			errors.append("deactivated_cylinders contains an invalid cylinder")
			break
	if cylinder_deactivation_enabled and deactivated_cylinders.is_empty():
		errors.append("cylinder deactivation requires explicit deactivated cylinders")
	if deactivation_enter_load >= deactivation_exit_load:
		errors.append("deactivation_enter_load must be below deactivation_exit_load")
	if deactivation_min_rpm >= deactivation_max_rpm:
		errors.append("deactivation_min_rpm must be below deactivation_max_rpm")
	if idle_rpm >= redline_rpm:
		errors.append("idle_rpm must be below redline_rpm")
	return errors


func get_event_frequency_hz(rpm: float) -> float:
	return maxf(rpm, 0.0) * float(cylinder_count) / 120.0


func get_bank_for_cylinder(cylinder_number: int) -> int:
	var index: int = cylinder_number - 1
	return cylinder_bank_by_number[index] if index >= 0 and index < cylinder_bank_by_number.size() else 0


func get_collector_for_cylinder(cylinder_number: int) -> int:
	var index: int = cylinder_number - 1
	return collector_group_by_cylinder[index] if index >= 0 and index < collector_group_by_cylinder.size() else 0


func is_cylinder_deactivated(cylinder_number: int) -> bool:
	return cylinder_deactivation_enabled and deactivated_cylinders.has(cylinder_number)
