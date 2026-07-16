extends SceneTree

const SOURCE_PATH := "res://assets/third_party/sketchfab/traffic_rider_npc_vehicles/bmw_4_series_f32/source/01_bmw_4_series_2014.glb"
const ARTIFACT_PATH := "res://build/test-logs/traffic-rider-bmw-f32-source.glb"
const EXPECTED_SHA256 := "fab5af5379c45f780f2ccc608560b99cb441ebf0f66c06e8eef0cb7fcd28d510"


func _initialize() -> void:
	var source_bytes := FileAccess.get_file_as_bytes(SOURCE_PATH)
	if source_bytes.is_empty():
		push_error("[BMW_F32_SOURCE_ARTIFACT_TEST] Source bytes could not be read")
		quit(1)
		return
	if FileAccess.get_sha256(SOURCE_PATH) != EXPECTED_SHA256:
		push_error("[BMW_F32_SOURCE_ARTIFACT_TEST] Committed source SHA-256 changed")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ARTIFACT_PATH.get_base_dir()))
	var output := FileAccess.open(ARTIFACT_PATH, FileAccess.WRITE)
	if output == null:
		push_error("[BMW_F32_SOURCE_ARTIFACT_TEST] Diagnostic artifact could not be opened")
		quit(1)
		return
	output.store_buffer(source_bytes)
	output.close()
	if FileAccess.get_sha256(ARTIFACT_PATH) != EXPECTED_SHA256:
		push_error("[BMW_F32_SOURCE_ARTIFACT_TEST] Diagnostic artifact SHA-256 mismatch")
		quit(1)
		return
	print("[BMW_F32_SOURCE_ARTIFACT_TEST] Source artifact written with verified SHA-256")
	quit(0)
