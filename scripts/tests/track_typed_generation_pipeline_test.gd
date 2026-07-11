extends SceneTree

const TRACK_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var track: GeneratedTrack = TRACK_SCENE.instantiate() as GeneratedTrack
	_expect(track != null, "track scene instantiates as GeneratedTrack")
	if track == null:
		_finish()
		return

	root.add_child(track)
	await process_frame
	await process_frame

	var layout: TrackLayoutResource = track.get_track_layout()
	var config: TrackGenerationConfig = TrackGenerationConfig.from_layout(layout)
	_expect(config != null and config.is_valid(), "typed generation config is valid")
	_expect(config.track_layout == layout, "typed config retains the authoritative layout")

	var geometry: TrackGeometryData = TrackLayoutBuilder.new().build(config)
	_expect(not geometry.center_points.is_empty(), "typed layout builder produces geometry")

	var generated_root: Node3D = Node3D.new()
	root.add_child(generated_root)
	var materials: TrackMaterialFactory = TrackMaterialFactory.new()
	var meshes: TrackGeneratedMeshes = TrackSurfaceMeshBuilder.new().build_surfaces(
		generated_root,
		geometry,
		materials,
		config
	)
	_expect(meshes != null and meshes.is_valid(), "surface builder returns typed shared meshes")
	_expect(meshes.track_mesh.get_surface_count() > 0, "track mesh contains a render surface")
	_expect(meshes.shoulder_mesh.get_surface_count() > 0, "shoulder mesh contains a render surface")

	TrackCollisionBuilder.new().build_collisions(generated_root, geometry, config, meshes)
	var track_body: TrackSurfaceBody = generated_root.get_node_or_null("TrackSurface") as TrackSurfaceBody
	var shoulder_body: TrackSurfaceBody = generated_root.get_node_or_null("RoadsideTerrain") as TrackSurfaceBody
	var grass_body: TrackSurfaceBody = generated_root.get_node_or_null("Grass") as TrackSurfaceBody
	_expect(track_body != null and track_body.get_node_or_null("CollisionShape3D") != null, "shared track mesh creates collision")
	_expect(shoulder_body != null and shoulder_body.get_node_or_null("CollisionShape3D") != null, "shared shoulder mesh creates collision")
	_expect(grass_body != null and grass_body.get_node_or_null("CollisionShape3D") != null, "typed config creates grass collision")
	_expect(_get_grip(track_body) > _get_grip(shoulder_body), "asphalt grip is higher than shoulder grip")
	_expect(_get_grip(shoulder_body) > _get_grip(grass_body), "shoulder grip is higher than grass grip")

	generated_root.queue_free()
	track.queue_free()
	await process_frame
	_finish()


func _get_grip(body: TrackSurfaceBody) -> float:
	return body.get_grip_multiplier() if body != null else -1.0


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRACK_TYPED_PIPELINE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRACK_TYPED_PIPELINE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRACK_TYPED_PIPELINE_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	for failure: String in _failures:
		push_error("[TRACK_TYPED_PIPELINE_TEST] - %s" % failure)
	quit(1)
