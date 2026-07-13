extends SceneTree

const TRACK_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")
const RUNTIME_CONTRACT_CHECKS: int = 240

var _checks: int = 0
var _failures: Array[String] = []


class ValidationCountingGeometry:
	extends TrackGeometryData

	var validation_calls: int = 0

	func is_valid() -> bool:
		validation_calls += 1
		return true


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var track: GeneratedTrack = TRACK_SCENE.instantiate() as GeneratedTrack
	_expect(not track.has_committed_generation(), "an unbuilt track has no committed generation")
	root.add_child(track)
	await process_frame

	_expect(track.has_committed_generation(), "the generated track publishes its committed state")
	var original_geometry: TrackGeometryData = track._geometry
	var counting_geometry: ValidationCountingGeometry = ValidationCountingGeometry.new()
	track._geometry = counting_geometry

	var remained_committed: bool = true
	for _check_index: int in range(RUNTIME_CONTRACT_CHECKS):
		remained_committed = remained_committed and track.has_committed_generation()

	_expect(remained_committed, "repeated runtime contract reads preserve the committed state")
	_expect(
		counting_geometry.validation_calls == 0,
		"runtime contract reads use the cached committed state instead of revalidating geometry"
	)

	track._geometry = original_geometry
	track.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[GENERATED_TRACK_RUNTIME_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[GENERATED_TRACK_RUNTIME_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[GENERATED_TRACK_RUNTIME_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[GENERATED_TRACK_RUNTIME_CONTRACT_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[GENERATED_TRACK_RUNTIME_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
