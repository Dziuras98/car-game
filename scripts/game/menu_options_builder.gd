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
	var ordered_variants: Array[CarVariantMenuOption] = []
	if car_catalog == null:
		return menu_models

	for model: CarModelDefinition in car_catalog.get_models():
		if model == null:
			continue
		var model_label: String = model.get_model_name()
		for variant: CarVariantDefinition in model.get_variants():
			if variant == null or variant.get_car_scene() == null:
				continue
			var specs: CarSpecs = variant.get_specs()
			if specs == null or not specs.is_valid():
				continue
			var performance_index: int = variant.get_performance_index()
			if performance_index <= 0:
				continue
			ordered_variants.append(CarVariantMenuOption.new(
				variant.variant_id,
				TranslationServer.translate(variant.get_menu_name()),
				performance_index,
				variant.get_car_scene(),
				specs,
				variant.engine_label,
				variant.drivetrain_label,
				model.model_id,
				model_label
			))

	ordered_variants.sort_custom(_is_car_option_ordered_before)

	# MainMenu flattens these entries in sequence. Splitting a model when needed
	# preserves a global ascending DPI order while retaining the correct model metadata.
	for variant: CarVariantMenuOption in ordered_variants:
		if not menu_models.is_empty():
			var previous_group: CarModelMenuOption = menu_models[menu_models.size() - 1]
			if previous_group.model_id == variant.model_id:
				previous_group.variants.append(variant)
				continue
		var group_variants: Array[CarVariantMenuOption] = [variant]
		menu_models.append(CarModelMenuOption.new(
			variant.model_id,
			variant.model_label,
			group_variants
		))

	return menu_models


static func _is_car_option_ordered_before(
	left: CarVariantMenuOption,
	right: CarVariantMenuOption
) -> bool:
	if left.performance_index != right.performance_index:
		return left.performance_index < right.performance_index
	return String(left.variant_id).casecmp_to(String(right.variant_id)) < 0
