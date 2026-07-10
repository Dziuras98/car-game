extends SceneTree

const SPEEDOMETER_SCENE: PackedScene = preload("res://scenes/ui/speedometer.tscn")
const AUTOMATIC_CAR_SCENE: PackedScene = preload("res://scenes/cars/370zat.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var test_root: Node3D = Node3D.new()
	test_root.name = "SpeedometerCarBindingTestRoot"
	get_root().add_child(test_root)

	var car: PlayerCarController = AUTOMATIC_CAR_SCENE.instantiate() as PlayerCarController
	_expect(car != null, "automatic 370Z scene instantiates as PlayerCarController")
	if car == null:
		test_root.queue_free()
		_finish()
		return

	test_root.add_child(car)
	var speedometer: CanvasLayer = SPEEDOMETER_SCENE.instantiate() as CanvasLayer
	_expect(speedometer != null, "speedometer scene instantiates")
	if speedometer == null:
		test_root.queue_free()
		_finish()
		return

	test_root.add_child(speedometer)
	await process_frame
	await process_frame

	_expect(car.car_specs != null, "spawned automatic car provides CarSpecs")
	_expect(_count_visible_meshes(car) > 0, "spawned automatic car contains visible mesh geometry")

	speedometer.call("set_target_node", car)
	await process_frame

	var gauge: TachometerGauge = speedometer.get_node_or_null(
		"Panel/VBoxContainer/TachometerGauge"
	) as TachometerGauge
	_expect(gauge != null, "speedometer exposes its tachometer gauge")
	if gauge != null and car.car_specs != null:
		_expect(
			is_equal_approx(gauge.max_rpm, car.car_specs.rev_limiter_rpm),
			"tachometer maximum RPM comes from the selected car specs"
		)
		_expect(
			is_equal_approx(gauge.redline_rpm, car.car_specs.redline_rpm),
			"tachometer redline comes from the selected car specs"
		)

	test_root.queue_free()
	await process_frame
	_finish()


func _count_visible_meshes(node: Node) -> int:
	var count: int = 0
	if node is MeshInstance3D and (node as MeshInstance3D).is_visible_in_tree():
		count += 1
	for child: Node in node.get_children():
		count += _count_visible_meshes(child)
	return count


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[SPEEDOMETER_BINDING_TEST][PASS] %s" % message)
		return

	_failures.append(message)
	push_error("[SPEEDOMETER_BINDING_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SPEEDOMETER_BINDING_TEST] Passed: %d checks" % _checks)
		quit(0)
		return

	push_error(
		"[SPEEDOMETER_BINDING_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[SPEEDOMETER_BINDING_TEST] - %s" % failure_message)
	quit(1)
