extends Node

const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")
const OPPONENT_COUNTS: Array[int] = [1, 4, 8, 12]
const SIMULATED_UPDATES: int = 180
const MAX_AVERAGE_POINT_CHECKS: float = 22.0

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var track: Node3D = SIMPLE_OVAL_SCENE.instantiate() as Node3D
	add_child(track)
	await get_tree().process_frame

	var racing_points: Array[Vector3] = _get_racing_points(track)
	_expect(racing_points.size() == 108, "performance fixture exposes the 108-point racing line")
	_test_racing_line_search_scaling(racing_points)
	_test_racing_line_recovery(racing_points)
	_test_audio_distance_lod()
	_test_ui_update_coalescing()
	await _test_track_rebuild_coalescing(track)

	track.queue_free()
	_finish()


func _test_racing_line_search_scaling(points: Array[Vector3]) -> void:
	if points.is_empty():
		return

	for opponent_count: int in OPPONENT_COUNTS:
		var searches: Array[RacingLineIndexSearch] = []
		var current_indices: Array[int] = []
		for opponent_index: int in range(opponent_count):
			var search: RacingLineIndexSearch = RacingLineIndexSearch.new()
			search.configure(4, 14, 45.0, 120)
			searches.append(search)
			current_indices.append(-1)

		var total_point_checks: int = 0
		var started_usec: int = Time.get_ticks_usec()
		for update_index: int in range(SIMULATED_UPDATES):
			for opponent_index: int in range(opponent_count):
				var simulated_point_index: int = (
					update_index + opponent_index * 7
				) % points.size()
				current_indices[opponent_index] = searches[opponent_index].find_nearest_index(
					points,
					points[simulated_point_index],
					current_indices[opponent_index]
				)
				total_point_checks += searches[opponent_index].get_last_distance_check_count()

		var elapsed_usec: int = Time.get_ticks_usec() - started_usec
		var query_count: int = opponent_count * SIMULATED_UPDATES
		var average_point_checks: float = float(total_point_checks) / float(query_count)
		print(
			"[PERFORMANCE_REGRESSION_TEST] AI=%d updates=%d checks=%d average=%.2f elapsed_usec=%d"
			% [opponent_count, query_count, total_point_checks, average_point_checks, elapsed_usec]
		)
		_expect(
			average_point_checks <= MAX_AVERAGE_POINT_CHECKS,
			"%d AI drivers stay within the bounded racing-line search budget" % opponent_count
		)


func _test_racing_line_recovery(points: Array[Vector3]) -> void:
	if points.size() < 80:
		return
	var search: RacingLineIndexSearch = RacingLineIndexSearch.new()
	search.configure(4, 14, 20.0, 120)
	var current_index: int = search.find_nearest_index(points, points[0], -1)
	current_index = search.find_nearest_index(points, points[70], current_index)
	_expect(current_index == 70, "bounded search falls back to a full scan after a large position jump")
	_expect(search.get_last_distance_check_count() > 19, "recovery scan is distinguishable from the normal local window")


func _test_audio_distance_lod() -> void:
	var audio_lod: ProceduralAudioPlayer3D = ProceduralAudioPlayer3D.new()
	audio_lod.procedural_generation_distance = 75.0
	_expect(audio_lod.is_position_audible(Vector3.ZERO, Vector3(75.0, 0.0, 0.0)), "audio generation includes the configured distance boundary")
	_expect(not audio_lod.is_position_audible(Vector3.ZERO, Vector3(75.1, 0.0, 0.0)), "audio generation excludes sources beyond the configured distance")

	var audible_opponents: int = 0
	for opponent_index: int in range(12):
		var opponent_position: Vector3 = Vector3(float(opponent_index + 1) * 18.0, 0.0, 0.0)
		if audio_lod.is_position_audible(opponent_position, Vector3.ZERO):
			audible_opponents += 1
	_expect(audible_opponents > 0 and audible_opponents < 12, "distance LOD disables procedural generation for remote opponents")
	audio_lod.free()


func _test_ui_update_coalescing() -> void:
	var lap_hud: LapPositionHud = LapPositionHud.new()
	lap_hud.build(self, 3)
	lap_hud.update(1, 3, 1, 4)
	var initial_text_updates: int = lap_hud.get_text_update_count()
	for update_index: int in range(120):
		lap_hud.update(1, 3, 1, 4)
	_expect(lap_hud.get_text_update_count() == initial_text_updates, "unchanged lap HUD values do not rewrite labels")
	lap_hud.update(2, 3, 2, 4)
	_expect(lap_hud.get_text_update_count() == initial_text_updates + 2, "changed lap and position values update each label once")

	var gauge: TachometerGauge = TachometerGauge.new()
	gauge.redraw_rpm_step = 20.0
	gauge.set_rpm(2000.0)
	var initial_redraws: int = gauge.get_redraw_request_count()
	for update_index: int in range(120):
		gauge.set_rpm(2005.0)
	_expect(gauge.get_redraw_request_count() == initial_redraws, "small repeated RPM changes do not redraw the tachometer")
	gauge.set_rpm(2050.0)
	_expect(gauge.get_redraw_request_count() == initial_redraws + 1, "meaningful RPM change redraws the tachometer once")

	gauge.major_tick_rpm = 0.0
	gauge.minor_tick_rpm = -10.0
	gauge.max_rpm = 1_000_000.0
	_expect(gauge.get_safe_tick_count(gauge.major_tick_rpm) == TachometerGauge.MAX_TICK_COUNT, "invalid major tick steps are bounded instead of entering an endless draw loop")
	_expect(gauge.get_safe_tick_count(gauge.minor_tick_rpm) == TachometerGauge.MAX_TICK_COUNT, "invalid minor tick steps are bounded instead of entering an endless draw loop")
	gauge.free()


func _test_track_rebuild_coalescing(track: Node3D) -> void:
	if track == null:
		return
	var initial_rebuild_count: int = int(track.call("get_rebuild_count"))
	for request_index: int in range(8):
		track.call("request_rebuild")
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(int(track.call("get_rebuild_count")) == initial_rebuild_count, "unchanged track rebuild requests are skipped")

	var layout: TrackLayoutResource = track.call("get_track_layout") as TrackLayoutResource
	if layout == null:
		_expect(false, "track exposes a layout for rebuild testing")
		return

	var original_width: float = layout.track_width
	layout.track_width = original_width + 0.5
	for change_index: int in range(5):
		layout.emit_changed()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(int(track.call("get_rebuild_count")) == initial_rebuild_count + 1, "multiple layout notifications coalesce into one rebuild")

	layout.track_width = original_width
	layout.emit_changed()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(int(track.call("get_rebuild_count")) == initial_rebuild_count + 2, "restoring layout data performs one final rebuild")


func _get_racing_points(track: Node3D) -> Array[Vector3]:
	var points: Array[Vector3] = []
	if track == null or not track.has_method("get_racing_line_points"):
		return points
	var raw_points: Array = track.call("get_racing_line_points")
	for point: Variant in raw_points:
		if point is Vector3:
			points.append(point)
	return points


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[PERFORMANCE_REGRESSION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[PERFORMANCE_REGRESSION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PERFORMANCE_REGRESSION_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[PERFORMANCE_REGRESSION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[PERFORMANCE_REGRESSION_TEST] - %s" % failure_message)
	get_tree().quit(1)
