extends SceneTree

const BASELINE_PATH := "res://docs/assets/traffic_rider_npc_vehicle_physics_v3_baseline.md"
const MASTER_PHYSICS_COMMIT := "3743f5e95391b63a97e81b95050984b8240b7f30"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var baseline: String = _read_text(BASELINE_PATH)
	_expect(not baseline.is_empty(), "physics v3 baseline document is readable")
	_expect_fragments(baseline, PackedStringArray([
		MASTER_PHYSICS_COMMIT,
		"PR #118, **Rework per-wheel vehicle physics and recalibrate DPI v3**",
		"`WheelTireState` is the authoritative state for all four wheel positions",
		"predictive longitudinal-force pass",
		"`DifferentialModel` then applies front-axle, rear-axle and centre coupling",
		"A fixed `awd_front_torque_fraction` alone is not accepted as final xDrive fidelity",
		"It does **not** yet reproduce the complete ZF 8HP architecture",
		"prohibited as the final fidelity path for approved ZF 8HP variants",
		"Any approved DCT variant requires two clutch paths",
		"Nissan 370Z 7AT resource as a dynamic 1000-point reference",
		"`CarVisualController` requires explicit detailed wheel bindings",
		"the current complete PR-head workflow passes",
	]), "baseline")
	_test_authoritative_runtime_files()
	_finish()


func _test_authoritative_runtime_files() -> void:
	_expect_fragments(_read_text("res://scripts/car/wheel_tire_state.gd"), PackedStringArray([
		"class_name WheelTireState",
		"const WHEEL_COUNT: int = 4",
		"var longitudinal_slip_ratio: float",
		"var lateral_slip_angle_rad: float",
		"var moment_of_inertia_kg_m2: float",
		"var drive_torque_nm: float",
	]), "per-wheel state")
	_expect_fragments(_read_text("res://scripts/car/differential_model.gd"), PackedStringArray([
		"class_name DifferentialModel",
		"config.front_differential_lock",
		"config.rear_differential_lock",
		"config.center_differential_lock",
	]), "differential")
	_expect_fragments(_read_text("res://scripts/car/car_powertrain_controller.gd"), PackedStringArray([
		"const MAX_SIMULATION_SUBSTEP: float = 1.0 / 120.0",
		"_differential_model.distribute_drive_torque",
		"var predicted_body_acceleration",
		"state.update_wheel_load_shares",
	]), "powertrain")
	_expect_fragments(_read_text("res://scripts/car/car_performance_index_calculator.gd"), PackedStringArray([
		"REFERENCE_SPECS: CarSpecs = preload(\"res://resources/cars/nissan/370z/specs/370z_7at_specs.tres\")",
		"TECHNICAL_COURSE",
		"MIXED_COURSE",
		"FAST_COURSE",
		"_apply_rotational_inertia",
	]), "DPI v3")
	_expect_fragments(_read_text("res://scripts/car/car_visual_controller.gd"), PackedStringArray([
		"CarVisualController detailed models require explicit wheel bindings.",
		"update_vehicle_wheel_visuals",
	]), "visual bindings")


func _expect_fragments(text: String, fragments: PackedStringArray, label: String) -> void:
	_expect(not text.is_empty(), "%s is readable" % label)
	for fragment: String in fragments:
		_expect(text.contains(fragment), "%s preserves: %s" % [label, fragment])


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRAFFIC_RIDER_PHYSICS_V3_BASELINE_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[TRAFFIC_RIDER_PHYSICS_V3_BASELINE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRAFFIC_RIDER_PHYSICS_V3_BASELINE_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRAFFIC_RIDER_PHYSICS_V3_BASELINE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	quit(1)
