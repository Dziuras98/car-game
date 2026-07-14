extends RefCounted
class_name MenuOptionsBuilder


static func build_track_options(track_catalog: TrackCatalog) -> Array[TrackMenuOption]:
	var track_options: Array[TrackMenuOption] = []
	if track_catalog == null:
		return track_options

	for definition: TrackDefinition in track_catalog.get_tracks():
		if definition == null or not definition.is_valid():
			continue
		track_options.append(TrackMenuOption.new(
			definition.track_id,
			TranslationServer.translate(definition.display_name),
			definition.recommended_laps
		))
	return track_options


static func build_car_models(car_catalog: CarCatalog) -> Array[CarModelMenuOption]:
	var menu_models: Array[CarModelMenuOption] = []
	if car_catalog == null:
		return menu_models

	for model: CarModelDefinition in car_catalog.get_models():
		if model == null:
			continue
		var variants: Array[CarVariantMenuOption] = []
		for variant: CarVariantDefinition in model.get_variants():
			if variant == null or variant.get_car_scene() == null:
				continue
			var specs: CarSpecs = variant.get_specs()
			if specs == null or not specs.is_valid():
				continue
			var performance_index: int = variant.get_performance_index()
			if performance_index <= 0:
				continue
			variants.append(CarVariantMenuOption.new(
				variant.variant_id,
				"%s — DPI %d" % [
					TranslationServer.translate(variant.get_menu_name()),
					performance_index,
				]
			))
		if not variants.is_empty():
			menu_models.append(CarModelMenuOption.new(
				model.model_id,
				model.get_model_name(),
				variants
			))

	return menu_models
