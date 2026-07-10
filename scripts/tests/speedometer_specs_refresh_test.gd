extends Node

const SPEEDOMETER_SCENE: PackedScene = preload("res://scenes/ui/speedometer.tscn")
const BASE_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var car: PlayerCarController = PlayerCarController.new()
	car.car_specs = BASE_SPECS
	add_child(car)
	car.set_physics_process(false)

	var speedometer: Speedometer = SPEEDOMETER_SCENE.instantiate() as Speedometer
	add_child(speedometer)
	await get_tree().process_frame
	speedometer.set_target_node(car)
	speedometer.call("_process", 1.0)
	var gauge: TachometerGauge = speedometer.get_node("Root/Panel/Margin/Content/TachometerGauge") as TachometerGauge
	_expect(gauge != null, "speedometer exposes the tachometer gauge")
	if gauge != null:
		_expect(is_equal_approx(gauge.max_rpm, BASE_SPECS.rev_limiter_rpm), "initial target specs configure the tachometer maximum")
		_expect(is_equal_approx(gauge.redline_rpm, BASE_SPECS.redline_rpm), "initial target specs configure the redline")

	var replacement: CarSpecs = BASE_SPECS.duplicate(true) as CarSpecs
	replacement.display_name = "Runtime replacement"
	replacement.redline_rpm = 7800.0
	replacement.rev_limiter_rpm = 8200.0
	car.car_specs = replacement
	speedometer.call("_process", 1.0)
	if gauge != null:
		_expect(is_equal_approx(gauge.max_rpm, 8200.0), "replacing specs on the same car refreshes the tachometer maximum")
		_expect(is_equal_approx(gauge.redline_rpm, 7800.0), "replacing specs on the same car refreshes the redline")

	replacement.redline_rpm = 7600.0
	replacement.rev_limiter_rpm = 8000.0
	speedometer.call("_process", 1.0)
	if gauge != null:
		_expect(is_equal_approx(gauge.max_rpm, 8000.0), "mutating the active specs resource is detected without replacing the car")
		_expect(is_equal_approx(gauge.redline_rpm, 7600.0), "mutated redline is detected without replacing the car")

	speedometer.set_target_node(null)
	_expect(not speedometer.is_processing(), "speedometer stops processing after its target is cleared")
	speedometer.queue_free()
	car.queue_free()
	await get_tree().process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[SPEEDOMETER_SPECS_REFRESH_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[SPEEDOMETER_SPECS_REFRESH_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SPEEDOMETER_SPECS_REFRESH_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[SPEEDOMETER_SPECS_REFRESH_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[SPEEDOMETER_SPECS_REFRESH_TEST] - %s" % failure_message)
	get_tree().quit(1)
