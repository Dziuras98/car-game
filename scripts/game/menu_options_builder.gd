extends RefCounted
class_name MenuOptionsBuilder


static func build_track_options(track_catalog: TrackCatalog) -> Array[Dictionary]:
	var track_options: Array[Dictionary] = []
	if track_catalog == null:
		return track_options

	for definition: TrackDefinition in track_catalog.get_tracks():
		if definition == null or not definition.is_valid():
			continue
		track_options.append({
			"label": definition.display_name,
			"track_id": str(definition.track_id),
			"recommended_laps": definition.recommended_laps,
		})
	return track_options


static func build_car_models(car_catalog: CarCatalog) -> Array[Dictionary]:
	var menu_models: Array[Dictionary] = []
	if car_catalog == null:
		return menu_models

	for model: CarModelDefinition in car_catalog.get_models():
		var variants: Array[Dictionary] = []
		for variant: CarVariantDefinition in model.get_variants():
			if variant == null or variant.get_car_scene() == null:
				continue
			var specs: CarSpecs = variant.get_specs()
			if specs == null or not specs.is_valid():
				continue
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

	return menu_models
