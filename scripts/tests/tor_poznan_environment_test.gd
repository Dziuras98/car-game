extends SceneTree

const TOR_POZNAN_SCENE: PackedScene = preload("res://scenes/tracks/tor_poznan.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var track: GeneratedTrack = TOR_POZNAN_SCENE.instantiate() as GeneratedTrack
	_expect(track != null, "Tor Poznań scene instantiates for environment validation")
	if track == null:
		_finish()
		return
	root.add_child(track)
	await process_frame
	await process_frame

	var environment: Node = track.get_node_or_null("TrackEnvironment")
	_expect(environment is TorPoznanEnvironment, "scene exposes the dedicated Tor Poznań environment")
	_expect(track.has_committed_generation(), "environment is attached to a committed generated track")
	_expect(environment.get_node_or_null("PitComplex/PitLane") is TrackSurfaceBody, "pit lane uses a drivable track surface")
	_expect(environment.get_node_or_null("PitComplex/PitEntry") is TrackSurfaceBody, "pit entry is physically connected")
	_expect(environment.get_node_or_null("PitComplex/PitExit") is TrackSurfaceBody, "pit exit is physically connected")
	_expect(_has_collision(environment, "PitComplex/PitLane"), "pit lane has physical collision")
	_expect(_has_collision(environment, "PitComplex/PitBuilding"), "pit building has physical collision")
	_expect(environment.get_node_or_null("PitComplex/ControlTower") is StaticBody3D, "control tower is present")
	_expect(environment.get_node_or_null("StartGantry/Crossbeam") is MeshInstance3D, "start gantry spans the main straight")
	_expect(environment.get_node_or_null("Grandstands/MainGrandstand") is Node3D, "main grandstand is present")
	_expect(environment.get_node_or_null("Grandstands/FirstCornerStand") is Node3D, "first-corner grandstand is present")

	var trunks: MultiMeshInstance3D = environment.get_node_or_null(
		"TracksideForest/TreeTrunks"
	) as MultiMeshInstance3D
	var crowns: MultiMeshInstance3D = environment.get_node_or_null(
		"TracksideForest/TreeCrowns"
	) as MultiMeshInstance3D
	_expect(trunks != null and trunks.multimesh != null, "forest trunks are batched")
	_expect(crowns != null and crowns.multimesh != null, "forest crowns are batched")
	if trunks != null and crowns != null and trunks.multimesh != null and crowns.multimesh != null:
		_expect(trunks.multimesh.instance_count >= 60, "track perimeter receives a dense tree line")
		_expect(
			trunks.multimesh.instance_count == crowns.multimesh.instance_count,
			"each generated trunk has one matching crown"
		)

	var red_curbs: MultiMeshInstance3D = environment.get_node_or_null(
		"CornerCurbs/RedCurbs"
	) as MultiMeshInstance3D
	var white_curbs: MultiMeshInstance3D = environment.get_node_or_null(
		"CornerCurbs/WhiteCurbs"
	) as MultiMeshInstance3D
	_expect(red_curbs != null and red_curbs.multimesh.instance_count > 0, "red corner curb segments are generated")
	_expect(white_curbs != null and white_curbs.multimesh.instance_count > 0, "white corner curb segments are generated")
	_expect(_pit_side_barrier_is_open(track), "generated barrier is opened along the pit lane")

	track.queue_free()
	await process_frame
	_finish()


func _has_collision(root_node: Node, path: String) -> bool:
	var body: Node = root_node.get_node_or_null(path)
	return body != null and body.get_node_or_null("CollisionShape3D") is CollisionShape3D


func _pit_side_barrier_is_open(track: GeneratedTrack) -> bool:
	var barriers: Node = track.get_node_or_null("GeneratedContent/Barriers")
	if barriers == null:
		return false
	var visual: MultiMeshInstance3D = barriers.get_node_or_null("BarrierVisuals") as MultiMeshInstance3D
	if visual == null or visual.multimesh == null:
		return false
	var hidden_count: int = 0
	for instance_index: int in range(visual.multimesh.instance_count):
		var transform: Transform3D = visual.multimesh.get_instance_transform(instance_index)
		if transform.origin.y < -900.0:
			hidden_count += 1
	return hidden_count > 0


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TOR_POZNAN_ENVIRONMENT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TOR_POZNAN_ENVIRONMENT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TOR_POZNAN_ENVIRONMENT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[TOR_POZNAN_ENVIRONMENT_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[TOR_POZNAN_ENVIRONMENT_TEST] - %s" % failure_message)
	quit(1)
