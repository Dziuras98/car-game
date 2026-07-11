extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []
var _original_locale: String = ""


func _initialize() -> void:
	_original_locale = TranslationServer.get_locale()
	var localization_errors: PackedStringArray = LocalizationCatalogLoader.ensure_loaded()
	_expect(localization_errors.is_empty(), "participant labels load localization catalogs")
	TranslationServer.set_locale("pl")

	var player_car: PlayerCarController = PlayerCarController.new()
	player_car.name = "ArbitraryPlayerNodeName"
	var opponent_car: PlayerCarController = PlayerCarController.new()
	opponent_car.name = "NameThatDoesNotContainAnOpponentNumber"
	var second_opponent_car: PlayerCarController = PlayerCarController.new()
	second_opponent_car.name = "Opponent999"

	var player: RaceParticipant = RaceParticipant.create_player(player_car)
	var first_opponent: RaceParticipant = RaceParticipant.create_opponent(opponent_car, 1)
	var second_opponent: RaceParticipant = RaceParticipant.create_opponent(second_opponent_car, 2)

	_expect(player != null and player.is_valid(), "player participant requires a stable id and car reference")
	_expect(player.is_player(), "player participant exposes typed player kind")
	_expect(player.get_participant_id() == &"player", "player participant uses a stable id")
	_expect(player.get_kind() == RaceParticipant.Kind.PLAYER, "player kind is read through the immutable identity API")
	_expect(player.get_car() == player_car, "player car reference is read through the immutable identity API")
	_expect(player.get_ordinal() == 0, "player participant has no opponent ordinal")
	_expect(player.get_display_label() == "Ty", "player label is derived from participant kind")

	_expect(first_opponent != null and first_opponent.is_valid(), "opponent participant is valid independently of node naming")
	_expect(not first_opponent.is_player(), "opponent participant exposes typed opponent kind")
	_expect(first_opponent.get_participant_id() == &"opponent_1", "first opponent uses a stable id")
	_expect(second_opponent.get_participant_id() == &"opponent_2", "second opponent uses a distinct stable id")
	_expect(
		first_opponent.get_ordinal() == 1 and second_opponent.get_ordinal() == 2,
		"opponent order is explicit immutable participant data"
	)
	_expect(first_opponent.get_display_label() == "Kierowca 1", "first opponent label ignores its node name")
	_expect(second_opponent.get_display_label() == "Kierowca 2", "second opponent label ignores misleading node numbering")

	second_opponent.set_display_name("Gość specjalny")
	_expect(second_opponent.get_display_name() == "Gość specjalny", "controlled display-name mutation is observable")
	_expect(second_opponent.get_display_label() == "Gość specjalny", "explicit participant display name overrides the generated label")
	_expect(RaceParticipant.create_opponent(opponent_car, 0) == null, "zero opponent ordinal is rejected instead of clamped")
	_expect(RaceParticipant.create_opponent(opponent_car, -1) == null, "negative opponent ordinal is rejected")
	_expect(RaceParticipant.create_player(null) == null, "player participant rejects a missing car")

	player_car.free()
	opponent_car.free()
	second_opponent_car.free()
	TranslationServer.set_locale(_original_locale)
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[RACE_PARTICIPANT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[RACE_PARTICIPANT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[RACE_PARTICIPANT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[RACE_PARTICIPANT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[RACE_PARTICIPANT_TEST] - %s" % failure_message)
	quit(1)
