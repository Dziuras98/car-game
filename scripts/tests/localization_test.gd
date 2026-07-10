extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var original_locale: String = TranslationServer.get_locale()
	var catalog_paths: PackedStringArray = LocalizationCatalogLoader.get_catalog_paths()
	_expect("res://translations/pl.po" in catalog_paths, "loader registers the Polish catalog path")
	_expect("res://translations/en.po" in catalog_paths, "loader registers the English catalog path")
	for catalog_path: String in catalog_paths:
		_expect(ResourceLoader.exists(catalog_path, "Translation"), "catalog is importable: %s" % catalog_path)

	var load_errors: PackedStringArray = LocalizationCatalogLoader.ensure_loaded()
	_expect(load_errors.is_empty(), "localization catalogs load without errors")
	_expect(LocalizationCatalogLoader.ensure_loaded().is_empty(), "localization loading is idempotent")

	TranslationServer.set_locale("pl")
	_expect(tr("Wyścig") == "Wyścig", "Polish locale preserves the source UI label")
	_expect(tr("Okrążenie %d/%d") % [2, 3] == "Okrążenie 2/3", "Polish formatted HUD label remains valid")

	TranslationServer.set_locale("en")
	_expect(tr("Wyścig") == "Race", "English locale translates the race mode")
	_expect(tr("Jazda swobodna") == "Free drive", "English locale translates free drive")
	_expect(tr("Okrążenie %d/%d") % [2, 3] == "Lap 2/3", "English locale preserves formatted HUD placeholders")
	_expect(tr("Wróć do menu") == "Return to menu", "English locale translates pause navigation")

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
