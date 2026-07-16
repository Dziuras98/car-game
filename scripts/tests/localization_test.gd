extends SceneTree

const CAR_CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const TRACK_CATALOG: TrackCatalog = preload("res://resources/tracks/catalog.tres")
const FATAL_CONFIGURATION_MESSAGE_PL: String = "Nie można uruchomić gry\n\nGame content configuration validation failed."
const FATAL_CONFIGURATION_MESSAGE_EN: String = "The game could not be started\n\nGame content configuration validation failed."
const LOADING_STAGE_KEYS: Array[String] = [
	"Sprawdzanie konfiguracji",
	"Przygotowywanie sesji",
	"Przygotowywanie toru",
	"Konfigurowanie symulacji",
	"Tworzenie samochodu",
	"Przygotowywanie przeciwników",
	"Finalizowanie sesji",
	"Gotowe",
]

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var original_locale: String = TranslationServer.get_locale()
	var catalog_paths: PackedStringArray = LocalizationCatalogLoader.get_catalog_paths()
	_expect(catalog_paths.size() == 2, "project config exposes exactly two localization catalogs")
	_expect("res://translations/pl.po" in catalog_paths, "project config registers the Polish catalog path")
	_expect("res://translations/en.po" in catalog_paths, "project config registers the English catalog path")
	_expect(LocalizationCatalogLoader.get_fallback_locale() == "pl", "Polish is the explicit fallback locale")

	for catalog_path: String in catalog_paths:
		_expect(ResourceLoader.exists(catalog_path, "Translation"), "catalog is importable: %s" % catalog_path)

	var load_errors: PackedStringArray = LocalizationCatalogLoader.ensure_loaded()
	_expect(load_errors.is_empty(), "localization catalogs load without errors")
	_expect(LocalizationCatalogLoader.ensure_loaded().is_empty(), "localization loading is idempotent")
	var supported_locales: PackedStringArray = LocalizationCatalogLoader.get_supported_locales()
	_expect("pl" in supported_locales, "loader discovers the Polish locale")
	_expect("en" in supported_locales, "loader discovers the English locale")

	TranslationServer.set_locale("pl")
	_expect(tr("Wyścig") == "Wyścig", "Polish locale preserves the race mode label")
	_expect(tr("Ładowanie...") == "Ładowanie...", "Polish locale preserves the loading title")
	_expect(tr("Wybierz") == "Wybierz", "Polish locale preserves the car confirmation action")
	_expect(tr("Moment obrotowy") == "Moment obrotowy", "Polish locale preserves the torque detail label")
	_expect(
		tr("Przygotowywanie toru i samochodów") == "Przygotowywanie toru i samochodów",
		"Polish locale preserves the loading description"
	)
	for stage_key: String in LOADING_STAGE_KEYS:
		_expect(tr(stage_key) == stage_key, "Polish locale preserves loading stage: %s" % stage_key)
	_expect(tr("Okrążenie %d/%d") % [2, 3] == "Okrążenie 2/3", "Polish formatted HUD label remains valid")
	_expect(tr("PRĘDKOŚĆ") == "PRĘDKOŚĆ", "Polish speedometer title preserves diacritics")
	_expect(tr("Kierowca %d") % 2 == "Kierowca 2", "Polish opponent result label preserves its placeholder")
	_expect(
		tr(FATAL_CONFIGURATION_MESSAGE_PL)
		== "Nie można uruchomić gry\n\nKonfiguracja zawartości gry jest nieprawidłowa.",
		"Polish fatal initialization screen does not retain an English technical message"
	)
	var polish_tracks: Array[TrackMenuOption] = MenuOptionsBuilder.build_track_options(TRACK_CATALOG)
	var polish_models: Array[CarModelMenuOption] = MenuOptionsBuilder.build_car_models(CAR_CATALOG)
	var polish_automatic: CarVariantMenuOption = _find_car_option(polish_models, &"nissan_370z_7at")
	_expect(not polish_tracks.is_empty() and polish_tracks[0].label == "Prosty owal", "Polish menu uses the localized track name")
	_expect(
		polish_automatic != null
		and polish_automatic.label == "370Z automat"
		and polish_automatic.performance_index > 0,
		"Polish menu keeps the variant label separate from its DPI metadata"
	)

	TranslationServer.set_locale("en")
	_expect(tr("Wyścig") == "Race", "English locale translates the race mode")
	_expect(tr("Jazda swobodna") == "Free drive", "English locale translates free drive")
	_expect(tr("Tryb") == "Mode", "English locale translates the menu context label")
	_expect(tr("Ładowanie...") == "Loading...", "English locale translates the loading title")
	_expect(tr("Wybierz") == "Select", "English locale translates the car confirmation action")
	_expect(tr("Silnik") == "Engine", "English locale translates the engine detail label")
	_expect(tr("Moment obrotowy") == "Torque", "English locale translates the torque detail label")
	_expect(tr("Napęd bezpośredni") == "Direct drive", "English locale translates direct-drive metadata")
	_expect(
		tr("Przygotowywanie toru i samochodów") == "Preparing the track and cars",
		"English locale translates the loading description"
	)
	var english_loading_stages: Array[String] = [
		"Checking configuration",
		"Preparing session",
		"Preparing track",
		"Configuring simulation",
		"Creating car",
		"Preparing opponents",
		"Finalizing session",
		"Ready",
	]
	for stage_index: int in range(LOADING_STAGE_KEYS.size()):
		_expect(
			tr(LOADING_STAGE_KEYS[stage_index]) == english_loading_stages[stage_index],
			"English locale translates loading stage: %s" % LOADING_STAGE_KEYS[stage_index]
		)
	_expect(tr("Brak dostępnych torów") == "No tracks available", "English locale translates menu validation feedback")
	_expect(tr("Okrążenie %d/%d") % [2, 3] == "Lap 2/3", "English locale preserves lap placeholders")
	_expect(tr("Pozycja %d/%d") % [1, 4] == "Position 1/4", "English locale preserves position placeholders")
	_expect(tr("Wyniki") == "Results", "English locale translates the results title")
	_expect(tr("Wróć do menu") == "Return to menu", "English locale translates pause and results navigation")
	_expect(tr("Kierowca %d") % 3 == "Driver 3", "English locale translates numbered opponent labels")
	_expect(tr("START") == "GO!", "English locale translates the race start banner")
	_expect(tr("PRĘDKOŚĆ") == "SPEED", "English locale translates the speedometer title")
	_expect(tr("BIEG") == "GEAR", "English locale translates the gear label")
	_expect(
		tr(FATAL_CONFIGURATION_MESSAGE_EN)
		== "The game could not be started\n\nGame content configuration is invalid.",
		"English fatal initialization screen uses user-facing wording"
	)
	var english_tracks: Array[TrackMenuOption] = MenuOptionsBuilder.build_track_options(TRACK_CATALOG)
	var english_models: Array[CarModelMenuOption] = MenuOptionsBuilder.build_car_models(CAR_CATALOG)
	var english_automatic: CarVariantMenuOption = _find_car_option(english_models, &"nissan_370z_7at")
	var english_manual: CarVariantMenuOption = _find_car_option(english_models, &"nissan_370z_6mt")
	_expect(not english_tracks.is_empty() and english_tracks[0].label == "Simple oval", "English menu translates the track name")
	_expect(
		english_automatic != null
		and english_manual != null
		and english_automatic.label == "370Z automatic"
		and english_manual.label == "370Z manual"
		and english_automatic.performance_index > 0
		and english_manual.performance_index > 0,
		"English menu translates variant labels and keeps DPI as structured metadata"
	)

	TranslationServer.set_locale(original_locale)
	_finish()


func _find_car_option(
	models: Array[CarModelMenuOption],
	variant_id: StringName
) -> CarVariantMenuOption:
	for model: CarModelMenuOption in models:
		if model == null:
			continue
		for option: CarVariantMenuOption in model.variants:
			if option != null and option.variant_id == variant_id:
				return option
	return null


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
