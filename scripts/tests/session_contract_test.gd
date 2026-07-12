extends SceneTree

const CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const GAME_MANAGER_SCRIPT = preload("res://scripts/game/game_manager.gd")
const REQUIRED_AI_VARIANT_IDS: Array[StringName] = [
	&"nissan_370z_7at",
	&"nissan_370z_nismo_7at_global",
]

var _checks: int = 0
var _failures: Array[String] = []


func _init() -> void:
	_expect(GAME_MANAGER_SCRIPT.is_supported_mode_id(GameModes.FREE_DRIVE), "free-drive mode is explicitly supported")
	_expect(GAME_MANAGER_SCRIPT.is_supported_mode_id(GameModes.RACE), "race mode is explicitly supported")
	_expect(not GAME_MANAGER_SCRIPT.is_supported_mode_id(&""), "empty mode IDs are rejected")
	_expect(not GAME_MANAGER_SCRIPT.is_supported_mode_id(&"practice"), "unknown mode IDs are rejected instead of falling back")

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260711
	var factory: CarInstanceFactory = CarInstanceFactory.new()
	var catalog_variants: Array[CarVariantDefinition] = CATALOG.get_all_variants()
	factory.configure(catalog_variants, rng)
	_expect(factory.has_available_cars(), "factory retains catalog player variants")
	_expect(factory.has_ai_eligible_cars(), "factory exposes explicit AI eligibility")

	var eligible_ids: Dictionary = {}
	var explicitly_eligible_count: int = 0
	for variant: CarVariantDefinition in catalog_variants:
		if variant == null or not variant.is_ai_eligible_for_race():
			continue
		explicitly_eligible_count += 1
		eligible_ids[variant.variant_id] = true
		_expect(variant.get_specs() != null and variant.get_specs().is_automatic_transmission(), "every AI-eligible variant uses a supported automatic transmission: %s" % str(variant.variant_id))
	_expect(factory.get_ai_eligible_count() == explicitly_eligible_count, "factory derives opponent variants only from explicit catalog AI eligibility")
	for required_id: StringName in REQUIRED_AI_VARIANT_IDS:
		_expect(eligible_ids.has(required_id), "required AI variant remains available: %s" % str(required_id))

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
