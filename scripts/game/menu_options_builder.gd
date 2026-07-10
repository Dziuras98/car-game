extends RefCounted
class_name MenuOptionsBuilder

const DEFAULT_TRACK_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")


static func build_track_options() -> Array[Dictionary]:
	var track_layouts: Array[TrackLayoutResource] = [DEFAULT_TRACK_LAYOUT]
	return build_track_options_from_layouts(track_layouts)


static func build_track_options_from_layouts(
	track_layouts: Array[TrackLayoutResource]
) -> Array[Dictionary]:
	var track_options: Array[Dictionary] = []
	var used_track_ids: Dictionary = {}

	for layout: TrackLayoutResource in track_layouts:
		if layout == null or not layout.is_valid():
			continue

		var track_id: String = str(layout.track_id)
		if used_track_ids.has(track_id):
			continue
		used_track_ids[track_id] = true

		track_options.append({
			"label": layout.display_name,
			"track_id": track_id,
			"recommended_laps": maxi(layout.recommended_laps, 1),
		})

	return track_options


static func build_car_models(
	car_catalog: CarCatalog,
	available_car_scenes: Array[PackedScene]
) -> Array[Dictionary]:
	var menu_models: Array[Dictionary] = []
	if car_catalog != null:
		for model: CarModelDefinition in car_catalog.get_models():
			var variants: Array[Dictionary] = []
			for variant: CarVariantDefinition in model.get_variants():
				variants.append({
					"label": variant.get_menu_name(),
					"variant_id": variant.variant_id,
				})
			if not variants.is_empty():
				menu_models.append({
					"label": model.get_model_name(),
					"model_id": model.model_id,
					"variants": variants,
				})

	if not menu_models.is_empty():
		return menu_models

	var fallback_variants: Array[Dictionary] = []
	for car_index: int in range(available_car_scenes.size()):
		fallback_variants.append({
			"label": "Samochod %d" % (car_index + 1),
			"variant_id": StringName(str(car_index)),
		})
	if not fallback_variants.is_empty():
		menu_models.append({
			"label": "Samochody",
			"model_id": &"fallback_cars",
			"variants": fallback_variants,
		})

	return menu_models


static func build_fallback_car_names(
	car_catalog: CarCatalog,
	available_car_variants: Array[CarVariantDefinition],
	available_car_scenes: Array[PackedScene]
) -> PackedStringArray:
	var car_names: PackedStringArray = PackedStringArray()
	if car_catalog != null and not available_car_variants.is_empty():
		for variant: CarVariantDefinition in available_car_variants:
			car_names.append(variant.get_menu_name())
	else:
		for car_index: int in range(available_car_scenes.size()):
			car_names.append("Samochod %d" % (car_index + 1))
	return car_names
