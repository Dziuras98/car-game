extends SceneTree

const MODEL: CarModelDefinition = preload("res://resources/cars/bmw/e46_sedan/model.tres")
const VISUAL_SCENE: PackedScene = preload("res://scenes/cars/bmw_e46_sedan_visuals.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_automatic_upshift_audio_load()
	_test_manual_upshift_audio_load_remains_cut()
	_test_preview_preparation_normalizes_visual_scale()
	_finish()


func _test_automatic_upshift_audio_load() -> void:
	var variant: CarVariantDefinition = MODEL.get_variant_by_id(&"bmw_e46_sedan_330i_5at")
	_expect(variant != null and variant.specs != null, "330i 5AT variant is available")
	if variant == null or variant.specs == null:
		return
	var config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(variant.specs)
	_expect(config != null and config.is_torque_converter_automatic(), "330i 5AT uses the torque-converter automatic configuration")
	if config == null:
		return

	var car := BmwE46CarController.new()
	car._drive_config = config
	car._powertrain_controller.configure(config)
	car._runtime_state.reset_drive_state(config.idle_rpm)
	car._powertrain_controller.reset(car._runtime_state)
	car._runtime_state.ground_contact_count = GroundContactModel.PROBE_COUNT
	car._runtime_state.current_gear = 1
	car._runtime_state.forward_speed = 18.0
	car._runtime_state.engine_rpm = config.redline_rpm
	car._powertrain_controller.update(car._runtime_state, 0.72, 0.0, false, false, false, 0.0)

	_expect(car._runtime_state.current_gear == 2 and car._runtime_state.shift_timer > 0.0, "330i 5AT enters an automatic upshift")
	_expect(is_equal_approx(car.get_engine_load(), 0.72), "330i 5AT keeps audio engine load tied to throttle during the upshift")
	_expect(is_zero_approx(car.get_drivetrain_load()), "330i 5AT still cuts wheel-side drivetrain load during the upshift")
	car.free()


func _test_manual_upshift_audio_load_remains_cut() -> void:
	var variant: CarVariantDefinition = MODEL.get_variant_by_id(&"bmw_e46_sedan_330i_6mt")
	_expect(variant != null and variant.specs != null, "330i 6MT variant is available")
	if variant == null or variant.specs == null:
		return
	var config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(variant.specs)
	if config == null:
		_expect(false, "330i 6MT drive configuration builds")
		return

	var car := BmwE46CarController.new()
	car._drive_config = config
	car._powertrain_controller.configure(config)
	car._runtime_state.reset_drive_state(config.idle_rpm)
	car._powertrain_controller.reset(car._runtime_state)
	car._runtime_state.current_gear = 2
	car._runtime_state.shift_timer = config.shift_delay
	car._runtime_state.clutch_engagement = 0.0
	car._runtime_state.set_drive_input_snapshot(0.72, 0.0)

	_expect(is_zero_approx(car.get_engine_load()), "330i 6MT retains the manual shift audio-load cut")
	car.free()


func _test_preview_preparation_normalizes_visual_scale() -> void:
	var visuals := VISUAL_SCENE.instantiate() as BmwE46VisualController
	_expect(visuals != null, "BMW E46 visual scene instantiates for preview")
	if visuals == null:
		return
	var detailed_root: Node3D = visuals.get_node_or_null(visuals.detailed_root_path) as Node3D
	var low_detail_root: Node3D = visuals.get_node_or_null(visuals.low_detail_root_path) as Node3D
	_expect(detailed_root != null and low_detail_root != null, "BMW E46 preview has detailed and low-detail roots")
	if detailed_root == null or low_detail_root == null:
		visuals.free()
		return
	var original_scale_length: float = detailed_root.scale.length()
	var renderer := CarPreviewRenderer.new()
	renderer._prepare_preview_tree(visuals)

	_expect(detailed_root.scale.length() < original_scale_length, "BMW E46 preview hook normalizes the oversized source model before rendering")
	_expect(detailed_root.visible, "BMW E46 detailed model is visible in the menu preview")
	_expect(not low_detail_root.visible, "BMW E46 low-detail fallback stays hidden in the menu preview")
	visuals.free()
	renderer.free()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[BMW_E46_PLAYER_AUDIO_PREVIEW_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[BMW_E46_PLAYER_AUDIO_PREVIEW_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[BMW_E46_PLAYER_AUDIO_PREVIEW_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[BMW_E46_PLAYER_AUDIO_PREVIEW_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[BMW_E46_PLAYER_AUDIO_PREVIEW_TEST] - %s" % failure_message)
	quit(1)
