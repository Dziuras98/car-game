extends RefCounted
class_name LocalizationCatalogLoader

const TRANSLATION_PATHS_SETTING: String = "internationalization/locale/translations"
const FALLBACK_LOCALE_SETTING: String = "internationalization/locale/fallback"

static var _registered_catalog_paths: Dictionary = {}


static func ensure_loaded() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var catalog_paths: PackedStringArray = get_catalog_paths()
	if catalog_paths.is_empty():
		errors.append("project defines no translation catalogs")
		return errors

	var locale_paths: Dictionary = {}
	for catalog_path: String in catalog_paths:
		if catalog_path.strip_edges().is_empty():
			errors.append("translation catalog path must not be empty")
			continue
		if not ResourceLoader.exists(catalog_path, "Translation"):
			errors.append("translation catalog does not exist: %s" % catalog_path)
			continue
		var catalog: Translation = ResourceLoader.load(catalog_path, "Translation") as Translation
		if catalog == null:
			errors.append("translation catalog did not load as Translation: %s" % catalog_path)
			continue

		var locale: String = catalog.get_locale().strip_edges()
		if locale.is_empty():
			errors.append("translation catalog has no locale: %s" % catalog_path)
			continue
		if locale_paths.has(locale):
			errors.append(
				"translation locale '%s' is defined by both %s and %s"
				% [locale, str(locale_paths[locale]), catalog_path]
			)
			continue
		locale_paths[locale] = catalog_path

		if not _registered_catalog_paths.has(catalog_path):
			TranslationServer.add_translation(catalog)
			_registered_catalog_paths[catalog_path] = true

	var fallback_locale: String = get_fallback_locale()
	if fallback_locale.is_empty():
		errors.append("project localization fallback must not be empty")
	elif not locale_paths.has(fallback_locale):
		errors.append(
			"project localization fallback '%s' has no configured catalog" % fallback_locale
		)
	return errors


static func get_catalog_paths() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var configured_paths: Variant = ProjectSettings.get_setting(
		TRANSLATION_PATHS_SETTING,
		PackedStringArray()
	)
	if configured_paths is PackedStringArray:
		for path: String in configured_paths:
			result.append(path)
	elif configured_paths is Array:
		for path: Variant in configured_paths:
			result.append(str(path))
	return result


static func get_fallback_locale() -> String:
	return str(ProjectSettings.get_setting(FALLBACK_LOCALE_SETTING, "")).strip_edges()


static func get_supported_locales() -> PackedStringArray:
	var locales: PackedStringArray = PackedStringArray()
	for catalog_path: String in get_catalog_paths():
		var catalog: Translation = ResourceLoader.load(catalog_path, "Translation") as Translation
		if catalog == null:
			continue
		var locale: String = catalog.get_locale().strip_edges()
		if not locale.is_empty() and locale not in locales:
			locales.append(locale)
	return locales
