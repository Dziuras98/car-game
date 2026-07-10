extends SceneTree

const StartupRouter = preload("res://scripts/game/startup_router.gd")
const STARTUP_SCENE_PATH: String = "res://scenes/startup.tscn"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run()
	_finish()


func _run() -> void:
	_expect(
		ProjectSettings.get_setting("application/run/main_scene", "") == STARTUP_SCENE_PATH,
		"project main scene points to the startup router"
	)
	_expect(
		StartupRouter.resolve_startup_scene(PackedStringArray(), false) == StartupRouter.MAIN_SCENE_PATH,
		"empty user arguments select the normal main scene"
	)
	_expect(
		StartupRouter.resolve_startup_scene(PackedStringArray(["--unrelated-option"]), false) == StartupRouter.MAIN_SCENE_PATH,
		"unrelated user arguments preserve the normal main scene"
	)
	_expect(
		StartupRouter.resolve_startup_scene(
			PackedStringArray([StartupRouter.EXPORT_SMOKE_ARGUMENT]),
			false
		) == StartupRouter.MAIN_SCENE_PATH,
		"production exports ignore the private smoke-test argument"
	)
	_expect(
		StartupRouter.resolve_startup_scene(
			PackedStringArray([StartupRouter.EXPORT_SMOKE_ARGUMENT]),
			true
		) == StartupRouter.EXPORTED_BUILD_SMOKE_SCENE_PATH,
		"test exports route the smoke argument to the packaged regression scene"
	)
	_expect(
		StartupRouter.resolve_startup_scene(
			PackedStringArray(["--unrelated-option", StartupRouter.EXPORT_SMOKE_ARGUMENT, "value"]),
			true
		) == StartupRouter.EXPORTED_BUILD_SMOKE_SCENE_PATH,
		"test export smoke argument is recognized among other user arguments"
	)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[STARTUP_ROUTER_TEST][PASS] %s" % message)
		return

	_failures.append(message)
	push_error("[STARTUP_ROUTER_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[STARTUP_ROUTER_TEST] Passed: %d checks" % _checks)
		quit(0)
		return

	push_error("[STARTUP_ROUTER_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[STARTUP_ROUTER_TEST] - %s" % failure_message)
	quit(1)
