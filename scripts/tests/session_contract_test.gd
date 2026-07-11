extends SceneTree

const CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const GAME_MANAGER_SCRIPT = preload("res://scripts/game/game_manager.gd")

var _checks: int = 0
var _failures: Array[String] = []


func _init() -> void:
	_expect(GAME_MANAGER_SCRIPT.is_supported_mode_id("free_drive"), "free-drive mode is explicitly supported")
	_expect(GAME_MANAGER_SCRIPT.is_supported_mode_id("race"), "race mode is explicitly supported")
	_expect(not GAME_MANAGER_SCRIPT.is_supported_mode_id(""), "empty mode IDs are rejected")
	_expect(not GAME_MANAGER_SCRIPT.is_supported_mode_id("practice"), "unknown mode IDs are rejected instead of falling back")

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260711
	var factory: CarInstanceFactory = CarInstanceFactory.new()
	factory.configure(CATALOG.get_all_variants(), rng)
	_expect(factory.has_available_cars(), "factory retains catalog player variants")
	_expect(factory.has_ai_eligible_cars(), "factory exposes explicit AI eligibility")
	_expect(factory.get_ai_eligible_count() == 1, "factory does not infer additional opponent variants")

	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[SESSION_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[SESSION_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SESSION_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[SESSION_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[SESSION_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
