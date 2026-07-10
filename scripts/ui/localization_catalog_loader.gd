extends RefCounted
class_name LocalizationCatalogLoader

const POLISH_CATALOG_PATH: String = "res://translations/pl.po"
const ENGLISH_CATALOG_PATH: String = "res://translations/en.po"

static var _catalogs_registered: bool = false


static func ensure_loaded() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if _catalogs_registered:
		return errors

	for catalog_path: String in [POLISH_CATALOG_PATH, ENGLISH_CATALOG_PATH]:
		if not ResourceLoader.exists(catalog_path, "Translation"):
			errors.append("translation catalog does not exist: %s" % catalog_path)
			continue
		var catalog: Resource = ResourceLoader.load(catalog_path, "Translation")
		if not catalog is Translation:
			errors.append("translation catalog did not load as Translation: %s" % catalog_path)
			continue
		TranslationServer.add_translation(catalog as Translation)

	_catalogs_registered = errors.is_empty()
	return errors


static func get_catalog_paths() -> PackedStringArray:
	return PackedStringArray([POLISH_CATALOG_PATH, ENGLISH_CATALOG_PATH])
