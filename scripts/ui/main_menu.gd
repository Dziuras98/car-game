extends CanvasLayer
class_name MainMenu

signal selection_completed(mode_id: StringName, track_id: StringName, car_variant_id: StringName)

const STEP_MODE: int = 0
const STEP_TRACK: int = 1
const STEP_CAR: int = 2
const STEP_LOADING: int = 3
const LOADING_PROGRESS_INITIAL: float = 4.0
const THUMBNAIL_RENDER_SIZE: Vector2i = Vector2i(320, 180)
const EMPTY_VALUE: String = "—"
const TRANSPARENT_FONT_COLOR: Color = Color(1.0, 1.0, 1.0, 0.0)

var _selected_mode_id: StringName = &""
var _selected_track_id: StringName = &""
var _selected_car_index: int = -1
var _current_step: int = STEP_MODE
var _car_models: Array[CarModelMenuOption] = []
var _flat_car_options: Array[CarVariantMenuOption] = []
var _track_options: Array[TrackMenuOption] = []
var _thumbnail_buttons: Array[Button] = []
var _thumbnail_button_group: ButtonGroup
var _thumbnail_render_generation: int = 0
var _center_preview: CarPreviewRenderer
var _thumbnail_renderer: CarPreviewRenderer

@onready var _selection_panel: PanelContainer = $Root/CenterContainer/PanelContainer
@onready var _title_label: Label = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var _subtitle_label: Label = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SubtitleLabel
@onready var _options: VBoxContainer = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Options
@onready var _back_button: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BackButton
@onready var _loading_panel: PanelContainer = $Root/CenterContainer/LoadingPanelContainer
@onready var _loading_subtitle_label: Label = $Root/CenterContainer/LoadingPanelContainer/MarginContainer/VBoxContainer/SubtitleLabel
@onready var _loading_details_label: Label = $Root/CenterContainer/LoadingPanelContainer/MarginContainer/VBoxContainer/DetailsLabel
@onready var _loading_progress: ProgressBar = $Root/CenterContainer/LoadingPanelContainer/MarginContainer/VBoxContainer/ProgressBar

@onready var _car_selection_panel: PanelContainer = $Root/CarSelectionPanelContainer
@onready var _current_model_label: Label = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/Header/CurrentModelLabel
@onready var _current_variant_label: Label = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/Header/CurrentVariantLabel
@onready var _preview_container: SubViewportContainer = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/Content/PreviewPanel/MarginContainer/PreviewContainer
@onready var _preview_unavailable_label: Label = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/Content/PreviewPanel/MarginContainer/PreviewUnavailableLabel
@onready var _thumbnail_scroll: ScrollContainer = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/ThumbnailScroll
@onready var _thumbnail_strip: HBoxContainer = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/ThumbnailScroll/ThumbnailStrip
@onready var _car_back_button: Button = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/Actions/BackButton
@onready var _choose_car_button: Button = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/Actions/ChooseButton

@onready var _engine_value: Label = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/Content/LeftDetails/MarginContainer/Details/EngineValue
@onready var _torque_value: Label = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/Content/LeftDetails/MarginContainer/Details/TorqueValue
@onready var _redline_value: Label = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/Content/LeftDetails/MarginContainer/Details/RedlineValue
@onready var _mass_value: Label = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/Content/LeftDetails/MarginContainer/Details/MassValue
@onready var _drivetrain_value: Label = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/Content/RightDetails/MarginContainer/Details/DrivetrainValue
@onready var _transmission_value: Label = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/Content/RightDetails/MarginContainer/Details/TransmissionValue
@onready var _top_speed_value: Label = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/Content/RightDetails/MarginContainer/Details/TopSpeedValue
@onready var _dpi_value: Label = $Root/CarSelectionPanelContainer/MarginContainer/VBoxContainer/Content/RightDetails/MarginContainer/Details/DpiValue


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_car_back_button.pressed.connect(_on_back_pressed)
	_choose_car_button.pressed.connect(_on_choose_car_pressed)
	_create_preview_renderers()
	_show_mode_step()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed(GameInputActions.UI_CANCEL):
		return
	if _current_step == STEP_LOADING:
		get_viewport().set_input_as_handled()
		return
	if _current_step != STEP_MODE:
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func reset_menu() -> void:
	show()
	_show_mode_step()


func is_loading_screen_visible() -> bool:
	return visible and _current_step == STEP_LOADING and _loading_panel.visible


func get_loading_progress() -> float:
	return _loading_progress.value if is_loading_screen_visible() else 0.0


func set_loading_progress(progress: float, status_text: String = "") -> void:
	if not is_loading_screen_visible():
		return
	var next_value: float = clampf(progress, 0.0, 1.0) * 100.0
	_loading_progress.value = maxf(_loading_progress.value, next_value)
	if not status_text.is_empty():
		_loading_subtitle_label.text = status_text


func complete_loading(success: bool) -> void:
	if success:
		hide()
		return
	reset_menu()


func set_car_models(next_car_models: Array[CarModelMenuOption]) -> void:
	_car_models = next_car_models.duplicate()
	_rebuild_flat_car_options()
	if is_inside_tree() and _current_step == STEP_CAR:
		_show_car_step()


func set_track_options(next_track_options: Array[TrackMenuOption]) -> void:
	_track_options = next_track_options.duplicate()
	if is_inside_tree() and _current_step == STEP_TRACK:
		_show_track_step()


func has_valid_options() -> bool:
	if _car_models.is_empty() or _track_options.is_empty() or _flat_car_options.is_empty():
		return false
	for model: CarModelMenuOption in _car_models:
		if model == null or not model.is_valid():
			return false
	for track: TrackMenuOption in _track_options:
		if track == null or not track.is_valid():
			return false
	return true


func _create_preview_renderers() -> void:
	if DisplayServer.get_name() == "headless":
		return

	_center_preview = CarPreviewRenderer.new()
	_center_preview.name = "CenterCarPreview"
	_preview_container.add_child(_center_preview)

	_thumbnail_renderer = CarPreviewRenderer.new()
	_thumbnail_renderer.name = "ThumbnailRenderer"
	_thumbnail_renderer.size = THUMBNAIL_RENDER_SIZE
	_thumbnail_renderer.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_thumbnail_renderer)


func _rebuild_flat_car_options() -> void:
	_flat_car_options.clear()
	for model: CarModelMenuOption in _car_models:
		if model == null:
			continue
		for variant: CarVariantMenuOption in model.variants:
			if variant == null or not variant.is_valid():
				continue
			variant.model_id = model.model_id
			variant.model_label = model.label
			_flat_car_options.append(variant)


func _show_current_step() -> void:
	match _current_step:
		STEP_TRACK:
			_show_track_step()
		STEP_CAR:
			_show_car_step()
		_:
			_show_mode_step()


func _show_mode_step() -> void:
	_show_selection_panel()
	_current_step = STEP_MODE
	_selected_mode_id = &""
	_selected_track_id = &""
	_selected_car_index = -1
	_title_label.text = tr("Car Game")
	_subtitle_label.text = tr("Wybierz tryb")
	_back_button.visible = false
	_clear_options()
	_add_option_button(tr("Jazda swobodna"), Callable(self, "_on_mode_pressed").bind(GameModes.FREE_DRIVE))
	_add_option_button(tr("Wyścig"), Callable(self, "_on_mode_pressed").bind(GameModes.RACE))
	_focus_first_option()


func _show_track_step() -> void:
	_show_selection_panel()
	_current_step = STEP_TRACK
	_selected_track_id = &""
	_selected_car_index = -1
	_title_label.text = tr("Wybierz tor")
	_subtitle_label.text = "%s: %s" % [tr("Tryb"), _get_mode_label(_selected_mode_id)]
	_back_button.visible = true
	_clear_options()

	if _track_options.is_empty():
		_show_configuration_error(tr("Brak dostępnych torów"))
		return
	for track_option: TrackMenuOption in _track_options:
		if track_option != null and track_option.is_valid():
			_add_option_button(
				track_option.label,
				Callable(self, "_on_track_pressed").bind(track_option.track_id)
			)
	_focus_first_option()


func _show_car_step() -> void:
	_current_step = STEP_CAR
	if _flat_car_options.is_empty():
		_show_selection_panel()
		_title_label.text = tr("Wybierz samochód")
		_show_configuration_error(tr("Brak dostępnych samochodów"))
		return

	_show_car_selection_panel()
	_build_car_thumbnails()
	_select_car(0, true)
	_thumbnail_render_generation += 1
	_render_thumbnail_images(_thumbnail_render_generation)


func _show_loading_step(car_variant_id: StringName) -> void:
	_current_step = STEP_LOADING
	_thumbnail_render_generation += 1
	_loading_progress.value = LOADING_PROGRESS_INITIAL
	_loading_subtitle_label.text = tr("Sprawdzanie konfiguracji")
	_selection_panel.hide()
	_car_selection_panel.hide()
	_loading_panel.show()
	_loading_details_label.text = "%s — %s\n%s — %s" % [
		_get_mode_label(_selected_mode_id),
		_get_track_label(_selected_track_id),
		_get_selected_model_label(),
		_get_variant_label(car_variant_id),
	]
	_clear_previews()
	show()


func _show_selection_panel() -> void:
	_thumbnail_render_generation += 1
	_loading_panel.hide()
	_car_selection_panel.hide()
	_selection_panel.show()
	_clear_previews()


func _show_car_selection_panel() -> void:
	_loading_panel.hide()
	_selection_panel.hide()
	_car_selection_panel.show()


func _show_configuration_error(message: String) -> void:
	_clear_options()
	_subtitle_label.text = message
	_back_button.visible = _current_step != STEP_MODE
	_focus_back_button()


func _clear_options() -> void:
	for child: Node in _options.get_children():
		_options.remove_child(child)
		child.queue_free()


func _add_option_button(text: String, pressed_callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 48.0)
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(pressed_callback)
	_options.add_child(button)


func _build_car_thumbnails() -> void:
	for child: Node in _thumbnail_strip.get_children():
		_thumbnail_strip.remove_child(child)
		child.queue_free()
	_thumbnail_buttons.clear()
	_thumbnail_button_group = ButtonGroup.new()
	_thumbnail_button_group.allow_unpress = false

	for car_index: int in range(_flat_car_options.size()):
		var variant: CarVariantMenuOption = _flat_car_options[car_index]
		var button := Button.new()
		button.name = "CarThumbnail%d" % car_index
		button.text = variant.label
		button.tooltip_text = "%s — %s" % [variant.model_label, variant.label]
		button.custom_minimum_size = Vector2(214.0, 150.0)
		button.focus_mode = Control.FOCUS_ALL
		button.toggle_mode = true
		button.button_group = _thumbnail_button_group
		button.clip_contents = true
		button.set_meta("car_index", car_index)
		_hide_button_text(button)
		button.pressed.connect(_on_car_thumbnail_pressed.bind(car_index))
		button.focus_entered.connect(_on_car_thumbnail_focused.bind(car_index))
		_thumbnail_strip.add_child(button)
		_thumbnail_buttons.append(button)

		var content := VBoxContainer.new()
		content.name = "Content"
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("separation", 3)
		button.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 8.0
		content.offset_top = 7.0
		content.offset_right = -8.0
		content.offset_bottom = -7.0

		var preview := TextureRect.new()
		preview.name = "Preview"
		preview.custom_minimum_size = Vector2(0.0, 88.0)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(preview)

		var model_label := Label.new()
		model_label.name = "ModelLabel"
		model_label.text = variant.model_label
		model_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		model_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		model_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		model_label.add_theme_font_size_override("font_size", 13)
		content.add_child(model_label)

		var footer := HBoxContainer.new()
		footer.name = "Footer"
		footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		footer.add_theme_constant_override("separation", 8)
		content.add_child(footer)

		var variant_label := Label.new()
		variant_label.name = "VariantLabel"
		variant_label.text = variant.label
		variant_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		variant_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		variant_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		variant_label.add_theme_font_size_override("font_size", 12)
		footer.add_child(variant_label)

		var dpi_label := Label.new()
		dpi_label.name = "PerformanceIndex"
		dpi_label.text = _format_dpi(variant.performance_index)
		dpi_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		dpi_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dpi_label.add_theme_font_size_override("font_size", 12)
		footer.add_child(dpi_label)


func _hide_button_text(button: Button) -> void:
	var color_names: Array[StringName] = [
		&"font_color",
		&"font_hover_color",
		&"font_pressed_color",
		&"font_focus_color",
		&"font_hover_pressed_color",
		&"font_disabled_color",
	]
	for color_name: StringName in color_names:
		button.add_theme_color_override(color_name, TRANSPARENT_FONT_COLOR)


func _select_car(car_index: int, grab_focus: bool = false) -> void:
	if car_index < 0 or car_index >= _flat_car_options.size():
		return
	_selected_car_index = car_index
	for thumbnail_index: int in range(_thumbnail_buttons.size()):
		_thumbnail_buttons[thumbnail_index].set_pressed_no_signal(thumbnail_index == car_index)
	var selected_button: Button = _get_thumbnail_button(car_index)
	if selected_button != null:
		_thumbnail_scroll.call_deferred("ensure_control_visible", selected_button)
		if grab_focus:
			selected_button.call_deferred("grab_focus")
	_update_selected_car_content()


func _update_selected_car_content() -> void:
	var variant: CarVariantMenuOption = _get_selected_variant()
	if variant == null:
		_set_empty_car_content()
		return

	_current_model_label.text = variant.model_label
	_current_variant_label.text = variant.label
	var specs: CarSpecs = variant.specs
	_engine_value.text = variant.engine_label if not variant.engine_label.strip_edges().is_empty() else EMPTY_VALUE
	_drivetrain_value.text = variant.drivetrain_label if not variant.drivetrain_label.strip_edges().is_empty() else EMPTY_VALUE
	_dpi_value.text = str(variant.performance_index) if variant.performance_index > 0 else EMPTY_VALUE

	if specs == null:
		_torque_value.text = EMPTY_VALUE
		_redline_value.text = EMPTY_VALUE
		_mass_value.text = EMPTY_VALUE
		_transmission_value.text = EMPTY_VALUE
		_top_speed_value.text = EMPTY_VALUE
	else:
		_torque_value.text = _format_integer_measurement(roundi(specs.peak_engine_torque), "Nm")
		_redline_value.text = _format_integer_measurement(roundi(specs.redline_rpm), "rpm")
		_mass_value.text = _format_integer_measurement(roundi(specs.vehicle_mass), "kg")
		_transmission_value.text = _format_transmission(specs)
		_top_speed_value.text = _format_integer_measurement(roundi(specs.max_forward_speed * 3.6), "km/h")

	_update_center_preview(variant)


func _set_empty_car_content() -> void:
	_current_model_label.text = tr("Samochód")
	_current_variant_label.text = EMPTY_VALUE
	var value_labels: Array[Label] = [
		_engine_value,
		_torque_value,
		_redline_value,
		_mass_value,
		_drivetrain_value,
		_transmission_value,
		_top_speed_value,
		_dpi_value,
	]
	for value_label: Label in value_labels:
		value_label.text = EMPTY_VALUE
	_clear_previews()


func _update_center_preview(variant: CarVariantMenuOption) -> void:
	if _center_preview == null:
		_preview_unavailable_label.visible = true
		return
	if not variant.has_preview():
		_center_preview.clear_car()
		_preview_unavailable_label.visible = true
		return
	_preview_unavailable_label.visible = not _center_preview.show_car(variant.car_scene, variant.specs, true)


func _render_thumbnail_images(generation: int) -> void:
	if DisplayServer.get_name() == "headless" or _thumbnail_renderer == null:
		return
	for car_index: int in range(_flat_car_options.size()):
		if generation != _thumbnail_render_generation or _current_step != STEP_CAR:
			return
		var variant: CarVariantMenuOption = _flat_car_options[car_index]
		if not variant.has_preview():
			continue
		if not _thumbnail_renderer.show_car(variant.car_scene, variant.specs, false):
			continue
		_thumbnail_renderer.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		await RenderingServer.frame_post_draw
		if generation != _thumbnail_render_generation or _current_step != STEP_CAR:
			return
		var image: Image = _thumbnail_renderer.capture_image()
		if image != null:
			var button: Button = _get_thumbnail_button(car_index)
			if button != null:
				var preview: TextureRect = button.get_node_or_null("Content/Preview") as TextureRect
				if preview != null:
					preview.texture = ImageTexture.create_from_image(image)
		_thumbnail_renderer.clear_car()
		_thumbnail_renderer.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _clear_previews() -> void:
	if _center_preview != null:
		_center_preview.clear_car()
	if _thumbnail_renderer != null:
		_thumbnail_renderer.clear_car()
		_thumbnail_renderer.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if _preview_unavailable_label != null:
		_preview_unavailable_label.visible = false


func _format_dpi(performance_index: int) -> String:
	if performance_index <= 0:
		return "%s %s" % [tr("DPI"), EMPTY_VALUE]
	return "%s %d" % [tr("DPI"), performance_index]


func _format_integer_measurement(value: int, unit: String) -> String:
	return "%d %s" % [value, unit]


func _format_transmission(specs: CarSpecs) -> String:
	if specs.is_smg_transmission():
		return "%d SMG" % specs.gear_ratios.size()
	if specs.is_manual_transmission():
		return "%d MT" % specs.gear_ratios.size()
	if specs.is_automatic_transmission():
		return "%d AT" % specs.gear_ratios.size()
	if specs.is_cvt_transmission():
		return "CVT"
	return tr("Napęd bezpośredni")


func _focus_first_option() -> void:
	for child: Node in _options.get_children():
		if child is Button:
			(child as Button).call_deferred("grab_focus")
			return
	_focus_back_button()


func _focus_back_button() -> void:
	if _back_button.visible:
		_back_button.call_deferred("grab_focus")


func _on_mode_pressed(mode_id: StringName) -> void:
	if not GameModes.is_supported(mode_id):
		_show_configuration_error(tr("Wybrany tryb nie jest dostępny"))
		return
	if not has_valid_options():
		_show_configuration_error(tr("Konfiguracja zawartości jest niepoprawna"))
		return
	_selected_mode_id = mode_id
	_show_track_step()


func _on_track_pressed(track_id: StringName) -> void:
	if _find_track_option(track_id) == null:
		_show_configuration_error(tr("Wybrany tor nie jest dostępny"))
		return
	_selected_track_id = track_id
	_show_car_step()


func _on_car_thumbnail_focused(car_index: int) -> void:
	_select_car(car_index)


func _on_car_thumbnail_pressed(car_index: int) -> void:
	_select_car(car_index)


func _on_choose_car_pressed() -> void:
	var variant: CarVariantMenuOption = _get_selected_variant()
	if variant == null:
		return
	_show_loading_step(variant.variant_id)
	await get_tree().process_frame
	await get_tree().process_frame
	selection_completed.emit(_selected_mode_id, _selected_track_id, variant.variant_id)


func _on_back_pressed() -> void:
	match _current_step:
		STEP_CAR:
			_show_track_step()
		STEP_TRACK:
			_show_mode_step()


func _get_mode_label(mode_id: StringName) -> String:
	match mode_id:
		GameModes.FREE_DRIVE:
			return tr("Jazda swobodna")
		GameModes.RACE:
			return tr("Wyścig")
		_:
			return tr("Nieznany tryb")


func _get_track_label(track_id: StringName) -> String:
	var option: TrackMenuOption = _find_track_option(track_id)
	return option.label if option != null else tr("Nieznany tor")


func _find_track_option(track_id: StringName) -> TrackMenuOption:
	for option: TrackMenuOption in _track_options:
		if option != null and option.track_id == track_id:
			return option
	return null


func _get_selected_model_label() -> String:
	var variant: CarVariantMenuOption = _get_selected_variant()
	return variant.model_label if variant != null else tr("Samochód")


func _get_variant_label(car_variant_id: StringName) -> String:
	for variant: CarVariantMenuOption in _flat_car_options:
		if variant.variant_id == car_variant_id:
			return variant.label
	return tr("Samochód")


func _get_selected_variant() -> CarVariantMenuOption:
	if _selected_car_index < 0 or _selected_car_index >= _flat_car_options.size():
		return null
	return _flat_car_options[_selected_car_index]


func _get_thumbnail_button(car_index: int) -> Button:
	for button: Button in _thumbnail_buttons:
		if int(button.get_meta("car_index", -1)) == car_index:
			return button
	return null
