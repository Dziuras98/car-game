extends SceneTree

const DEFAULT_CAR_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_6mt_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var tree_root: Window = get_root()
	var car: PlayerCarController = PlayerCarController.new()
	tree_root.add_child(car)
	await process_frame

	var initial_emitter: SkidMarkEmitter = car._skid_mark_emitter
	_expect(initial_emitter != null, "car creates skid mark emitter during ready")
	if initial_emitter == null:
		car.queue_free()
		await process_frame
		_finish()
		return

	_expect(is_instance_valid(initial_emitter._parent), "skid mark emitter creates a parent container")
	if not is_instance_valid(initial_emitter._parent):
		car.queue_free()
		await process_frame
		_finish()
		return

	_expect(_count_skid_mark_containers(tree_root) == 1, "initial configure creates one SkidMarks container")

	var initial_parent: Node3D = initial_emitter._parent
	var target_specs: CarSpecs = _build_target_specs()

	car._runtime_state.forward_speed = 8.5
	car._runtime_state.lateral_speed = 1.25
	car._runtime_state.engine_rpm = 3600.0
	car._runtime_state.current_gear = 6
	car.car_specs = target_specs
	await process_frame

	_expect(car._drive_config != null, "runtime reconfiguration rebuilds drive config")
	if car._drive_config != null:
		_expect(is_equal_approx(car._drive_config.skid_mark_min_slip, target_specs.skid_mark_min_slip), "drive config applies new skid mark min slip")
		_expect(is_equal_approx(car._drive_config.skid_mark_interval, target_specs.skid_mark_interval), "drive config applies new skid mark interval")
		_expect(is_equal_approx(car._drive_config.skid_mark_lifetime, target_specs.skid_mark_lifetime), "drive config applies new skid mark lifetime")
		_expect(is_equal_approx(car._drive_config.skid_mark_width, target_specs.skid_mark_width), "drive config applies new skid mark width")
		_expect(is_equal_approx(car._drive_config.skid_mark_length, target_specs.skid_mark_length), "drive config applies new skid mark length")

	_expect(car._skid_mark_emitter == initial_emitter, "runtime reconfiguration reuses existing skid mark emitter")
	if car._skid_mark_emitter != null:
		_expect(car._skid_mark_emitter._parent == initial_parent, "runtime reconfiguration reuses existing SkidMarks parent")
		_expect(is_equal_approx(car._skid_mark_emitter.min_slip, target_specs.skid_mark_min_slip), "skid mark emitter applies new min slip")
		_expect(is_equal_approx(car._skid_mark_emitter.interval, target_specs.skid_mark_interval), "skid mark emitter applies new interval")
		_expect(is_equal_approx(car._skid_mark_emitter.lifetime, target_specs.skid_mark_lifetime), "skid mark emitter applies new lifetime")
		_expect(is_equal_approx(car._skid_mark_emitter.mark_width, target_specs.skid_mark_width), "skid mark emitter applies new mark width")
		_expect(is_equal_approx(car._skid_mark_emitter.mark_length, target_specs.skid_mark_length), "skid mark emitter applies new mark length")
	_expect(_count_skid_mark_containers(tree_root) == 1, "runtime reconfiguration does not create duplicate SkidMarks containers")

	_expect(car._runtime_state.current_gear == target_specs.gear_ratios.size(), "runtime reconfiguration clamps gear to new forward gear count")
	_expect(is_equal_approx(car._runtime_state.forward_speed, 8.5), "runtime reconfiguration preserves forward speed")
	_expect(is_equal_approx(car._runtime_state.lateral_speed, 1.25), "runtime reconfiguration preserves lateral speed")
	_expect(is_equal_approx(car._runtime_state.engine_rpm, 3600.0), "runtime reconfiguration preserves engine rpm")

	car.queue_free()
	if is_instance_valid(initial_parent):
		initial_parent.queue_free()
	await process_frame
	_finish()


func _build_target_specs() -> CarSpecs:
	var specs: CarSpecs = DEFAULT_CAR_SPECS.duplicate(true) as CarSpecs
	specs.display_name = "Runtime Reconfiguration Test Specs"
	specs.gear_ratios = [3.10, 2.05]
	specs.skid_mark_min_slip = 0.72
	specs.skid_mark_interval = 0.12
	specs.skid_mark_lifetime = 3.5
	specs.skid_mark_width = 0.31
	specs.skid_mark_length = 1.4
	return specs


func _count_skid_mark_containers(node: Node) -> int:
	var count: int = 0
	for child: Node in node.get_children():
		if String(child.name).begins_with("SkidMarks"):
			count += 1
		count += _count_skid_mark_containers(child)
	return count


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CAR_SPECS_RECONFIG_TEST][PASS] %s" % message)
		return

	_failures.append(message)
	push_error("[CAR_SPECS_RECONFIG_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CAR_SPECS_RECONFIG_TEST] Passed: %d checks" % _checks)
		quit(0)
		return

	push_error("[CAR_SPECS_RECONFIG_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CAR_SPECS_RECONFIG_TEST] - %s" % failure_message)
	quit(1)
