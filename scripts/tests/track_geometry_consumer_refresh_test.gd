extends Node

const SIMPLE_OVAL_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")
const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")
const TEST_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var mutable_layout: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	var track: GeneratedTrack = SIMPLE_OVAL_SCENE.instantiate() as GeneratedTrack
	track.name = "Track"
	track.track_layout = mutable_layout
	add_child(track)
	await get_tree().process_frame

	var car: PlayerCarController = PlayerCarController.new()
	car.name = "Car"
	car.car_specs = TEST_SPECS
	add_child(car)

	var profile: AiDriverProfile = AiDriverProfile.new()
	profile.lane_offset = 1.25
	var driver: AiRaceDriver = AiRaceDriver.new()
	driver.name = "Driver"
	_expect(driver.configure(car, track, profile), "AI accepts a typed car, committed track and valid profile")
	add_child(driver)

	var minimap: Minimap = Minimap.new()
	minimap.name = "Minimap"
	minimap.size = Vector2(240.0, 180.0)
	add_child(minimap)
	minimap.set_track_node(track)
	minimap.set_target_node(car)

	await get_tree().process_frame
	var initial_track_revision: int = track.get_geometry_revision()
	var initial_driver_revision: int = driver.get_point_revision()
	var initial_minimap_revision: int = minimap.get_track_revision()
	_expect(initial_track_revision >= 1, "generated track publishes an initial geometry revision")
	_expect(initial_driver_revision >= 1, "AI caches the initial racing line")
	_expect(driver.get_cached_point_count() >= 3, "AI validates and caches a usable racing line")
	_expect(driver.is_configured(), "AI runtime contract remains valid after entering the tree")
	_expect(is_equal_approx(driver.get_profile().lane_offset, 1.25), "AI retains a defensive copy of its typed profile")
	_expect(initial_minimap_revision >= 1, "minimap caches the initial racing line")
	_expect(not driver.is_physics_processing(), "disabled AI driver does not consume physics frames")

	driver.set_driver_enabled(true)
	_expect(driver.is_physics_processing(), "enabled AI driver activates physics processing")
	driver.set_driver_enabled(false)
	_expect(not driver.is_physics_processing(), "disabled AI driver stops physics processing")

	mutable_layout.track_width += 0.5
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(track.get_geometry_revision() == initial_track_revision + 1, "layout change rebuilds the generated track once")
	_expect(driver.get_point_revision() == initial_driver_revision + 1, "AI refreshes its racing-line cache after rebuild")
	_expect(minimap.get_track_revision() == initial_minimap_revision + 1, "minimap refreshes its projection after rebuild")

	var minimap_revision_after_rebuild: int = minimap.get_track_revision()
	track.global_position += Vector3(18.0, 0.0, -7.0)
	await get_tree().process_frame
	_expect(
		minimap.get_track_revision() == minimap_revision_after_rebuild + 1,
		"minimap refreshes cached world points when the track transform changes"
	)
	_expect(
		minimap._track_points[0].is_equal_approx(track.to_global(track.get_racing_line_points()[0])),
		"minimap world-point cache follows the transformed track"
	)

	minimap.queue_free()
	driver.queue_free()
	car.queue_free()
	track.queue_free()
	await get_tree().process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRACK_GEOMETRY_CONSUMER_REFRESH_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRACK_GEOMETRY_CONSUMER_REFRESH_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRACK_GEOMETRY_CONSUMER_REFRESH_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[TRACK_GEOMETRY_CONSUMER_REFRESH_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRACK_GEOMETRY_CONSUMER_REFRESH_TEST] - %s" % failure_message)
	get_tree().quit(1)
