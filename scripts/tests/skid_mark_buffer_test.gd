extends Node

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var owner: Node3D = Node3D.new()
	owner.name = "Owner"
	add_child(owner)
	await get_tree().process_frame

	var emitter: SkidMarkEmitter = SkidMarkEmitter.new()
	emitter.configure(owner, 0.1, 0.01, 0.2, 0.2, 0.8)
	var capacity: int = emitter.get_capacity()
	_expect(capacity >= SkidMarkEmitter.MIN_CAPACITY, "skid buffer allocates a bounded minimum capacity")
	_expect(capacity <= SkidMarkEmitter.MAX_CAPACITY, "skid buffer never exceeds the global capacity limit")
	_expect(emitter.get_render_node_count() == 1, "all skid marks share one MultiMesh render node")

	for step: int in range(400):
		emitter.update(0.01, 1.0, Transform3D(Basis(), Vector3(float(step) * 0.05, 0.0, 0.0)))
	_expect(emitter.get_render_node_count() == 1, "long drifts do not create additional scene nodes")
	_expect(emitter.get_active_count() <= capacity, "active skid segments remain inside the ring buffer")

	for step: int in range(40):
		emitter.update(0.01, 0.0, Transform3D.IDENTITY)
	_expect(emitter.get_active_count() == 0, "expired skid segments are recycled and hidden")

	emitter.reset_timer()
	_expect(emitter.get_active_count() == 0, "reset clears the complete skid buffer")
	emitter.dispose()
	owner.queue_free()
	await get_tree().process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[SKID_MARK_BUFFER_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[SKID_MARK_BUFFER_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SKID_MARK_BUFFER_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[SKID_MARK_BUFFER_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[SKID_MARK_BUFFER_TEST] - %s" % failure_message)
	get_tree().quit(1)
