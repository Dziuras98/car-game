extends Node

const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const EXPORTED_BUILD_SMOKE_SCENE_PATH: String = "res://scenes/tests/exported_build_smoke_test.tscn"
const EXPORT_SMOKE_ARGUMENT: String = "--export-smoke-test"


func _ready() -> void:
	call_deferred("_route_startup")


func _route_startup() -> void:
	var target_scene_path: String = resolve_startup_scene(OS.get_cmdline_user_args())
	var scene_change_error: Error = get_tree().change_scene_to_file(target_scene_path)
	if scene_change_error == OK:
		return

	push_error(
		"[STARTUP_ROUTER] Failed to load startup scene '%s' with error %d."
		% [target_scene_path, scene_change_error]
	)
	get_tree().quit(1)


static func resolve_startup_scene(user_args: PackedStringArray) -> String:
	if EXPORT_SMOKE_ARGUMENT in user_args:
		return EXPORTED_BUILD_SMOKE_SCENE_PATH

	return MAIN_SCENE_PATH
