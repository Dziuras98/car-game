extends SceneTree

const CAR_CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var selection: CarSelectionState = CarSelectionState.new()
	selection.configure(CAR_CATALOG)
	_expect(selection.has_available_options(), "selection fixture exposes catalog variants")
	_expect(
		not selection.has_method("get_valid_car_index"),
		"selection state no longer exposes a clamping index fallback"
	)
	_expect(
		selection.get_car_index_for_variant_id(&"missing_variant") == -1,
		"unknown variant IDs return the explicit invalid index"
	)
	_expect(
		selection.get_variant_id_for_index(-1) == &"",
		"negative catalog indices are rejected"
	)
	_expect(
		selection.get_variant_id_for_index(selection.get_available_car_count()) == &"",
		"indices above the catalog range are rejected"
	)

	var opponent_spawner: OpponentParticipantSpawner = OpponentParticipantSpawner.new()
	var opponents: Array[PlayerCarController] = opponent_spawner.spawn_opponents(-1)
	_expect(opponents.is_empty(), "negative opponent counts do not create participants")
	_expect(
		opponent_spawner.get_last_spawn_result() == OpponentParticipantSpawner.Result.INVALID_COUNT,
		"negative opponent counts expose a distinct typed result"
	)

	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[STRICT_SELECTION_AND_COUNT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[STRICT_SELECTION_AND_COUNT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[STRICT_SELECTION_AND_COUNT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[STRICT_SELECTION_AND_COUNT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[STRICT_SELECTION_AND_COUNT_TEST] - %s" % failure_message)
	quit(1)
