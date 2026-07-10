extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_default_profile_validation()
	_test_invalid_profile_validation()
	_test_profile_copy_is_independent()
	_test_deterministic_profile_generation()
	_finish()


func _test_default_profile_validation() -> void:
	var profile: AiDriverProfile = AiDriverProfile.new()
	_expect(profile.is_valid(), "default AI driver profile is valid")
	_expect(profile.corner_speed_kmh <= profile.target_speed_kmh, "default corner speed does not exceed target speed")
	_expect(profile.search_points_behind + profile.search_points_ahead >= 1, "default profile has a non-empty local search window")


func _test_invalid_profile_validation() -> void:
	var profile: AiDriverProfile = AiDriverProfile.new()
	profile.lookahead_points = 0
	profile.target_speed_kmh = 40.0
	profile.corner_speed_kmh = 60.0
	profile.search_points_behind = 0
	profile.search_points_ahead = 0
	profile.recovery_search_distance = 0.0
	profile.full_search_interval_updates = 0
	profile.stuck_detection_seconds = -1.0
	profile.reverse_recovery_seconds = 0.0
	var errors: PackedStringArray = profile.validate()
	_expect(not errors.is_empty(), "invalid AI profile reports validation errors")
	_expect(errors.has("lookahead_points must be at least one"), "invalid lookahead is rejected")
	_expect(errors.has("corner_speed_kmh must not exceed target_speed_kmh"), "corner speed above target speed is rejected")
	_expect(errors.has("the racing-line search window must contain at least two points"), "empty search window is rejected")
	_expect(errors.has("full_search_interval_updates must be at least one"), "invalid full-search interval is rejected")


func _test_profile_copy_is_independent() -> void:
	var profile: AiDriverProfile = AiDriverProfile.new()
	profile.lane_offset = 1.75
	var copy: AiDriverProfile = profile.duplicate_profile()
	copy.lane_offset = -3.0
	copy.target_speed_kmh = 101.0
	_expect(is_equal_approx(profile.lane_offset, 1.75), "profile duplication does not alias lane offset")
	_expect(not is_equal_approx(profile.target_speed_kmh, copy.target_speed_kmh), "profile duplication does not alias speed tuning")


func _test_deterministic_profile_generation() -> void:
	var factory: OpponentAiProfileFactory = OpponentAiProfileFactory.new()
	var first: AiDriverProfile = factory.create_profile(123456, 2, -1.4)
	var replay: AiDriverProfile = factory.create_profile(123456, 2, -1.4)
	var other_index: AiDriverProfile = factory.create_profile(123456, 3, 1.4)

	_expect(first.is_valid() and replay.is_valid() and other_index.is_valid(), "generated AI profiles satisfy the runtime contract")
	_expect(is_equal_approx(first.target_speed_kmh, replay.target_speed_kmh), "same seed and opponent index reproduce target speed")
	_expect(is_equal_approx(first.corner_speed_kmh, replay.corner_speed_kmh), "same seed and opponent index reproduce corner speed")
	_expect(is_equal_approx(first.lane_offset, replay.lane_offset), "same seed and opponent index reproduce lane offset")
	_expect(
		not is_equal_approx(first.target_speed_kmh, other_index.target_speed_kmh)
		or not is_equal_approx(first.corner_speed_kmh, other_index.corner_speed_kmh),
		"opponent index selects an independent deterministic profile stream"
	)
	_expect(
		first.target_speed_kmh >= OpponentAiProfileFactory.MIN_TARGET_SPEED_KMH
		and first.target_speed_kmh <= OpponentAiProfileFactory.MAX_TARGET_SPEED_KMH,
		"generated target speed remains inside the configured range"
	)
	_expect(
		first.corner_speed_kmh >= OpponentAiProfileFactory.MIN_CORNER_SPEED_KMH
		and first.corner_speed_kmh <= OpponentAiProfileFactory.MAX_CORNER_SPEED_KMH,
		"generated corner speed remains inside the configured range"
	)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[AI_DRIVER_PROFILE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[AI_DRIVER_PROFILE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[AI_DRIVER_PROFILE_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[AI_DRIVER_PROFILE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[AI_DRIVER_PROFILE_TEST] - %s" % failure_message)
	quit(1)
