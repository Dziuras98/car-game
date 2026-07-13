extends SceneTree

const AVAILABLE_CAR_COUNT: int = 4
const SAMPLE_COUNT_PER_CAR: int = 128

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 370
	var factory: CarInstanceFactory = CarInstanceFactory.new()
	factory.configure(_make_variants(AVAILABLE_CAR_COUNT), rng)

	for current_index: int in range(AVAILABLE_CAR_COUNT):
		var all_indices_valid: bool = true
		var active_index_never_selected: bool = true
		var observed_indices: Dictionary = {}
		for _sample_index: int in range(SAMPLE_COUNT_PER_CAR):
			var selected_index: int = factory.get_random_available_index_excluding(current_index)
			all_indices_valid = all_indices_valid and selected_index >= 0 and selected_index < AVAILABLE_CAR_COUNT
			active_index_never_selected = active_index_never_selected and selected_index != current_index
			observed_indices[selected_index] = true
		_expect(all_indices_valid, "random car switch always selects a configured car")
		_expect(active_index_never_selected, "random car switch excludes active index %d" % current_index)
		_expect(
			observed_indices.size() == AVAILABLE_CAR_COUNT - 1,
			"random car switch can reach every alternative for active index %d" % current_index
		)

	var unselected_index: int = factory.get_random_available_index_excluding(-1)
	_expect(
		unselected_index >= 0 and unselected_index < AVAILABLE_CAR_COUNT,
		"random selection without an active car returns a configured index"
	)

	factory.configure(_make_variants(1), rng)
	_expect(
		factory.get_random_available_index_excluding(0) == -1,
		"single-car catalogs do not reload the active car"
	)

	factory.configure(_make_variants(0), rng)
	_expect(
		factory.get_random_available_index_excluding(-1) == -1,
		"empty catalogs cannot select a car"
	)

	_finish()


func _make_variants(count: int) -> Array[CarVariantDefinition]:
	var variants: Array[CarVariantDefinition] = []
	for _variant_index: int in range(count):
		variants.append(CarVariantDefinition.new())
	return variants


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[RANDOM_CAR_SWITCH_SELECTION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[RANDOM_CAR_SWITCH_SELECTION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[RANDOM_CAR_SWITCH_SELECTION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[RANDOM_CAR_SWITCH_SELECTION_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[RANDOM_CAR_SWITCH_SELECTION_TEST] - %s" % failure_message)
	quit(1)
