extends Node

const INFINITE_GRID_SCENE: PackedScene = preload("res://scenes/tracks/infinite_grid.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var track: InfiniteGridTrack = INFINITE_GRID_SCENE.instantiate() as InfiniteGridTrack
	_expect(track != null, "infinite grid scene instantiates as InfiniteGridTrack")
	if track == null:
		_finish()
		return

	add_child(track)
	await get_tree().process_frame
	_expect(track.has_committed_generation(), "infinite grid reports committed runtime content")
	_expect(track.get_track_layout() == null, "infinite grid does not expose a closed circuit layout")
	_expect(track.get_checkpoint_count() == 0, "infinite grid has no race checkpoints")
	_expect(track.get_checkpoint_gate_count() == 0, "infinite grid has no checkpoint gates")
	_expect(track.get_racing_line_points().size() == 4, "infinite grid exposes stable minimap bounds")

	var visual_floor: MeshInstance3D = track.get_node_or_null("VisualFloor") as MeshInstance3D
	_expect(visual_floor != null and visual_floor.mesh is PlaneMesh, "infinite grid uses a flat visual plane")
	if visual_floor != null and visual_floor.mesh is PlaneMesh:
		var plane_mesh: PlaneMesh = visual_floor.mesh as PlaneMesh
		_expect(
			plane_mesh.size.x >= 8000.0 and plane_mesh.size.y >= 8000.0,
			"visual plane covers the camera horizon before recentering"
		)
		var material: ShaderMaterial = plane_mesh.material as ShaderMaterial
		_expect(material != null and material.shader != null, "grid plane uses a procedural shader")
		if material != null and material.shader != null:
			_expect(
				is_equal_approx(float(material.get_shader_parameter("minor_spacing")), 1.0),
				"orange grid spacing is one metre"
			)
			_expect(
				is_equal_approx(float(material.get_shader_parameter("major_spacing")), 10.0),
				"red grid spacing is ten metres"
			)
			_expect(
				float(material.get_shader_parameter("major_half_width"))
				> float(material.get_shader_parameter("minor_half_width")),
				"ten-metre red grid lines are thicker than one-metre orange lines"
			)
			_expect(
				material.shader.code.contains("world_position.xz"),
				"grid coordinates remain anchored in world space while the plane recenters"
			)

	var collision_shape: CollisionShape3D = track.get_node_or_null(
		"Surface/CollisionShape3D"
	) as CollisionShape3D
	_expect(
		collision_shape != null and collision_shape.shape is WorldBoundaryShape3D,
		"map uses an infinite world-boundary collision plane"
	)
	var surface: TrackSurfaceBody = track.get_node_or_null("Surface") as TrackSurfaceBody
	_expect(surface != null and is_equal_approx(surface.get_grip_multiplier(), 1.0), "grid surface uses neutral grip")

	track.queue_free()
	await get_tree().process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[INFINITE_GRID_TRACK_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[INFINITE_GRID_TRACK_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[INFINITE_GRID_TRACK_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[INFINITE_GRID_TRACK_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[INFINITE_GRID_TRACK_TEST] - %s" % failure_message)
	get_tree().quit(1)
