extends SceneTree

const SPEEDOMETER_SCENE: PackedScene = preload("res://scenes/ui/speedometer.tscn")
const AUTOMATIC_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")
const MANUAL_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_6mt_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var original_locale: String = TranslationServer.get_locale()
	var localization_errors: PackedStringArray = LocalizationCatalogLoader.ensure_loaded()
	_expect(localization_errors.is_empty(), "localization catalogs load for the speedometer car display test")
	TranslationServer.set_locale("pl")

	var automatic_dpi: int = CarPerformanceIndexCalculator.calculate(AUTOMATIC_SPECS)
	var manual_dpi: int = CarPerformanceIndexCalculator.calculate(MANUAL_SPECS)
	_expect(automatic_dpi > 0 and manual_dpi > 0, "speedometer test cars receive positive performance indices")

	var speedometer: Speedometer = SPEEDOMETER_SCENE.instantiate() as Speedometer
	root.add_child(speedometer)
	await process_frame

	var automatic_car: PlayerCarController = PlayerCarController.new()
	automatic_car.car_specs = AUTOMATIC_SPECS
	var manual_car: PlayerCarController = PlayerCarController.new()
	manual_car.car_specs = MANUAL_SPECS

	speedometer.set_target_node(automatic_car)
	_expect(
		speedometer.get_displayed_car_name() == "370Z automat — DPI %d" % automatic_dpi,
		"speedometer identifies the initially loaded automatic car and its DPI"
	)

	speedometer.set_target_node(manual_car)
	_expect(
		speedometer.get_displayed_car_name() == "370Z manual — DPI %d" % manual_dpi,
		"speedometer updates the loaded car name and DPI after the target changes"
	)

	TranslationServer.set_locale("en")
	speedometer.set_target_node(automatic_car)
	_expect(
		speedometer.get_displayed_car_name() == "370Z automatic — DPI %d" % automatic_dpi,
		"loaded car name uses the active localization while preserving DPI"
	)

	speedometer.set_target_node(null)
	_expect(speedometer.get_displayed_car_name().is_empty(), "clearing the car target clears the loaded car name")

	speedometer.queue_free()
	automatic_car.free()
	manual_car.free()
	TranslationServer.set_locale(original_locale)
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[SPEEDOMETER_CAR_DISPLAY_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[SPEEDOMETER_CAR_DISPLAY_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SPEEDOMETER_CAR_DISPLAY_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[SPEEDOMETER_CAR_DISPLAY_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[SPEEDOMETER_CAR_DISPLAY_TEST] - %s" % failure_message)
	quit(1)
