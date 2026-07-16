extends SceneTree

const LAYOUT: TrackLayoutResource = preload("res://resources/tracks/high_speed_ring_layout.tres")
const DEFINITION: TrackDefinition = preload("res://resources/tracks/high_speed_ring_definition.tres")
const TRACK_SCENE: PackedScene = preload("res://scenes/tracks/high_speed_ring.tscn")
const MANIFEST_PATH: String = "res://assets/tracks/high_speed_ring/split_manifest.json"
const EXPECTED_PART_COUNT: int = 17
const MAX_PART_BYTES: int = 5 * 1024 * 1024

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_expect(LAYOUT != null and LAYOUT.is_valid(), "high speed ring layout is valid")
	_expect(LAYOUT.track_id == &"high_speed_ring", "layout uses the production track id")
	_expect(LAYOUT.display_name == "High Speed Ring", "layout exposes the production display name")
	_expect(LAYOUT.recommended_laps == 3, "layout recommends three laps")
	_expect(LAYOUT.control_points.size() == 84, "layout retains all 84 source-derived control points")
	_expect(_get_control_polygon_length() > 3900.0 and _get_control_polygon_length() < 4150.0, "layout length remains approximately 4.03 km")
	_expect(LAYOUT.control_points[0].distance_to(Vector3.ZERO) < 0.01, "start line is aligned to the project origin")
	_expect(LAYOUT.control_points[1].x > LAYOUT.control_points[0].x, "forward direction leaves the start along positive X")
	_expect(LAYOUT.get_track_width_at(0.0) > LAYOUT.get_track_width_at(0.5), "start and finish straight retains its wider source geometry")
	_expect(not LAYOUT.banking_degrees_profile.is_empty(), "source-derived banking profile is configured")
	_expect(_get_max_abs_banking() <= TrackLayoutResource.MAX_BANKING_DEGREES, "banking remains within the generated-track contract")
	_expect(LAYOUT.get_checkpoint_count() == 4, "layout defines four intermediate checkpoints")

	_expect(DEFINITION != null and DEFINITION.is_valid(), "high speed ring definition is valid")
	_expect(DEFINITION.track_id == LAYOUT.track_id, "definition and layout ids match")
	_expect(DEFINITION.track_scene == TRACK_SCENE, "definition references the production scene")
	_expect(
		DEFINITION.supports_mode(GameModes.FREE_DRIVE) and DEFINITION.supports_mode(GameModes.RACE),
		"high speed ring supports free drive and race modes"
	)

	var model_paths: PackedStringArray = HighSpeedRingVisualLoader._get_model_paths()
	_expect(model_paths.size() == EXPECTED_PART_COUNT, "visual loader declares all 17 parts")
	for index: int in range(EXPECTED_PART_COUNT):
		var expected_path: String = "res://assets/tracks/high_speed_ring/part_%03d.glb" % (index + 1)
		_expect(model_paths[index] == expected_path, "visual part %03d uses the canonical path" % (index + 1))
		_expect(ResourceLoader.exists(expected_path, "PackedScene"), "visual part %03d imports as a PackedScene" % (index + 1))
	_expect(
		is_equal_approx(
			HighSpeedRingVisualLoader._get_source_to_project_transform().origin.y,
			HighSpeedRingVisualLoader.VISUAL_VERTICAL_OFFSET
		),
		"visual loader applies only the documented vertical separation"
	)

	_validate_manifest(model_paths)
	_validate_scene_contract()
	_finish()


func _get_control_polygon_length() -> float:
	var length: float = 0.0
	for index: int in range(LAYOUT.control_points.size()):
		length += LAYOUT.control_points[index].distance_to(
			LAYOUT.control_points[(index + 1) % LAYOUT.control_points.size()]
		)
	return length


func _get_max_abs_banking() -> float:
	var maximum: float = 0.0
	for sample: Vector2 in LAYOUT.banking_degrees_profile:
		maximum = maxf(maximum, absf(sample.y))
	return maximum


func _validate_manifest(model_paths: PackedStringArray) -> void:
	_expect(FileAccess.file_exists(MANIFEST_PATH), "split manifest exists")
	if not FileAccess.file_exists(MANIFEST_PATH):
		return

	var parsed_manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	_expect(parsed_manifest is Dictionary, "split manifest parses as a dictionary")
	if not (parsed_manifest is Dictionary):
		return

	var manifest: Dictionary = parsed_manifest
	_expect(int(manifest.get("source_bytes", 0)) == 68264572, "manifest records the exact source size")
	_expect(int(manifest.get("source_objects", 0)) == 127, "manifest records every source mesh node")
	var parts_value: Variant = manifest.get("parts", [])
	_expect(parts_value is Array, "manifest exposes a parts array")
	if not (parts_value is Array):
		return

	var parts: Array = parts_value
	_expect(parts.size() == EXPECTED_PART_COUNT, "manifest contains all 17 parts")
	for index: int in range(mini(parts.size(), EXPECTED_PART_COUNT)):
		var part_value: Variant = parts[index]
		_expect(part_value is Dictionary, "manifest part %03d is a dictionary" % (index + 1))
		if not (part_value is Dictionary):
			continue
		var part: Dictionary = part_value
		_expect(String(part.get("path", "")) == model_paths[index].get_file(), "manifest part %03d path matches the loader" % (index + 1))
		_expect(int(part.get("bytes", 0)) > 0 and int(part.get("bytes", 0)) < MAX_PART_BYTES, "manifest part %03d remains below 5 MiB" % (index + 1))
		_expect(int(part.get("objects", 0)) == int(part.get("validated_meshes", -1)), "manifest part %03d validates every assigned mesh" % (index + 1))


func _validate_scene_contract() -> void:
	var scene_instance: Node = TRACK_SCENE.instantiate()
	_expect(scene_instance is GeneratedTrack, "production scene root uses GeneratedTrack")
	if scene_instance is GeneratedTrack:
		var generated_track: GeneratedTrack = scene_instance as GeneratedTrack
		_expect(generated_track.track_layout == LAYOUT, "production scene uses the high speed ring layout")
	var visual_loader: Node = scene_instance.get_node_or_null("SplitVisualAssets")
	_expect(visual_loader is HighSpeedRingVisualLoader, "production scene contains the split visual loader")
	scene_instance.free()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[HIGH_SPEED_RING_CONTENT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[HIGH_SPEED_RING_CONTENT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[HIGH_SPEED_RING_CONTENT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[HIGH_SPEED_RING_CONTENT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[HIGH_SPEED_RING_CONTENT_TEST] - %s" % failure_message)
	quit(1)
