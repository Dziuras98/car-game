extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var original_locale: String = TranslationServer.get_locale()
	TranslationServer.set_locale("pl")
	_expect(tr("Wyścig") == "Wyścig", "Polish locale preserves the source UI label")
	_expect(tr("Okrążenie %d/%d") % [2, 3] == "Okrążenie 2/3", "Polish formatted HUD label remains valid")

	TranslationServer.set_locale("en")
	_expect(tr("Wyścig") == "Race", "English locale translates the race mode")
	_expect(tr("Jazda swobodna") == "Free drive", "English locale translates free drive")
	_expect(tr("Okrążenie %d/%d") % [2, 3] == "Lap 2/3", "English locale preserves formatted HUD placeholders")
	_expect(tr("Wróć do menu") == "Return to menu", "English locale translates pause navigation")

	var translations: PackedStringArray = ProjectSettings.get_setting("internationalization/locale/translations", PackedStringArray())
	_expect("res://translations/pl.po" in translations, "project settings register the Polish catalog")
	_expect("res://translations/en.po" in translations, "project settings register the English catalog")
	TranslationServer.set_locale(original_locale)
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[LOCALIZATION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[LOCALIZATION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[LOCALIZATION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[LOCALIZATION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[LOCALIZATION_TEST] - %s" % failure_message)
	quit(1)
