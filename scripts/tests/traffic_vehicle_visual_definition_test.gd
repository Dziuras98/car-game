extends SceneTree

const DEFINITION_PATH := "res://resources/traffic/vehicles/bmw_4_series_f32.tres"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var definition := ResourceLoader.load(DEFINITION_PATH) as TrafficVehicleVisualDefinition
	_expect(definition != null, "BMW F32 visual definition loads")
	if definition == null:
		_finish()
		return
	_expect(definition.validate().is_empty(), "committed BMW F32 visual definition validates")
	_expect(definition.processed_visual_ready, "committed BMW F32 visual definition is processed")
	_test_source_hash(definition)
	_test_source_axis(definition)
	_test_reference_geometry(definition)
	_test_processed_visual_gate(definition)
	_finish()


func _test_source_hash(definition: TrafficVehicleVisualDefinition) -> void:
	var invalid := definition.duplicate(true) as TrafficVehicleVisualDefinition
	invalid.source_sha256 = "0".repeat(64)
	_expect(
		invalid.validate().has("source_sha256 does not match the committed source bytes"),
		"source byte changes cannot be hidden behind metadata"
	)


func _test_source_axis(definition: TrafficVehicleVisualDefinition) -> void:
	var invalid := definition.duplicate(true) as TrafficVehicleVisualDefinition
	invalid.source_front_axis = "+Y"
	_expect(
		_contains_fragment(invalid.validate(), "source_front_axis must be one of"),
		"unsupported source front axes are rejected"
	)


func _test_reference_geometry(definition: TrafficVehicleVisualDefinition) -> void:
	var invalid_scale := definition.duplicate(true) as TrafficVehicleVisualDefinition
	invalid_scale.visual_scale *= 1.01
	_expect(
		invalid_scale.validate().has("visual_scale must equal wheelbase_m / source_wheelbase_units"),
		"visual scale remains wheelbase-derived"
	)
	var invalid_clearance := definition.duplicate(true) as TrafficVehicleVisualDefinition
	invalid_clearance.ground_clearance_m = -0.01
	_expect(
		invalid_clearance.validate().has("ground_clearance_m must not be negative"),
		"negative ground clearance is rejected"
	)


func _test_processed_visual_gate(definition: TrafficVehicleVisualDefinition) -> void:
	var incomplete := definition.duplicate(true) as TrafficVehicleVisualDefinition
	incomplete.front_left_wheel_path = NodePath()
	_expect(
		incomplete.validate().has("processed visuals require explicit body and four wheel paths"),
		"processed state requires explicit body and four-wheel paths"
	)


func _contains_fragment(values: PackedStringArray, fragment: String) -> bool:
	for value: String in values:
		if value.contains(fragment):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRAFFIC_VEHICLE_VISUAL_DEFINITION_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[TRAFFIC_VEHICLE_VISUAL_DEFINITION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRAFFIC_VEHICLE_VISUAL_DEFINITION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRAFFIC_VEHICLE_VISUAL_DEFINITION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	quit(1)
