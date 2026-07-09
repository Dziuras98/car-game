@tool
extends EditorScript

const SMOKE_TEST_SCENE_PATH: String = "res://scenes/tests/full_program_smoke_test.tscn"


func _run() -> void:
	print("[SMOKE] Launching full program smoke test scene: %s" % SMOKE_TEST_SCENE_PATH)
	get_editor_interface().play_custom_scene(SMOKE_TEST_SCENE_PATH)
