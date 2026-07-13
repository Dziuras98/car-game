extends CanvasLayer
class_name MainMenu

signal selection_completed(mode_id: StringName, track_id: StringName, car_variant_id: StringName)

const STEP_MODE: int = 0
const STEP_TRACK: int = 1
const STEP_MODEL: int = 2
const STEP_VARIANT: int = 3
const STEP_LOADING: int = 4
const LOADING_PROGRESS_MINIMUM: float = 12.0
const LOADING_PROGRESS_RANGE: float = 76.0
const LOADING_PROGRESS_SPEED: float = 4.0

var _selected_mode_id: StringName = &""
var _selected_track_id: StringName = &""
var _selected_model_index: int = -1
var _current_step: int = STEP_MODE
var _car_models: Array[CarModelMenuOption] = []
var _track_options: Array[TrackMenuOption] = []
var _loading_elapsed: float = 0.0

@onready var _selection_panel: PanelContainer = $Root/CenterContainer/PanelContainer
@onready var _title_label: Label = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var _subtitle_label: Label = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SubtitleLabel
@onready var _options: VBoxContainer = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Options
@onready var _back_button: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BackButton
@onready var _loading_panel: PanelContainer = $Root/CenterContainer/LoadingPanelContainer
@onready var _loading_details_label: Label = $Root/CenterContainer/LoadingPanelContainer/MarginContainer/VBoxContainer/DetailsLabel
@onready var _loading_progress: ProgressBar = $Root/CenterContainer/LoadingPanelContainer/MarginContainer/VBoxContainer/ProgressBar


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_show_mode_step()


func _process(delta: float) -> void:
	if _current_step != STEP_LOADING or not visible:
		return
	_loading_elapsed += delta
	_loading_progress.value = LOADING_PROGRESS_MINIMUM + LOADING_PROGRESS_RANGE * (
		0.5 + 0.5 * sin(_loading_elapsed * LOADING_PROGRESS_SPEED)
	)


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


func set_car_models(next_car_models: Array[CarModelMenuOption]) -> void:
	_car_models = next_car_models.duplicate()
	if is_inside_tree() and (_current_step == STEP_MODEL or _current_step == STEP_VARIANT):
		_show_current_step()


func set_track_options(next_track_options: Array[TrackMenuOption]) -> void:
	_track_options = next_track_options.duplicate()
	if is_inside_tree() and _current_step == STEP_TRACK:
		_show_track_step()


func has_valid_options() -> bool:
	if _car_models.is_empty() or _track_options.is_empty():
		return false
	for model: CarModelMenuOption in _car_models:
		if model == null or not model.is_valid():
			return false
	for track: TrackMenuOption in _track_options:
		if track == null or not track.is_valid():
			return false
	return true


func _show_current_step() -> void:
	match _current_step:
		STEP_TRACK:
			_show_track_step()
		STEP_MODEL:
			_show_model_step()
		STEP_VARIANT:
			_show_variant_step()
		_:
			_show_mode_step()


func _show_mode_step() -> void:
	_show_selection_panel()
	_current_step = STEP_MODE
	_selected_mode_id = &""
	_selected_track_id = &""
	_selected_model_index = -1
	_title_label.text = tr("Car Game")
	_subtitle_label.text = tr("Wybierz tryb")
	_back_button.visible = false
	_clear_options()
	_add_option_button(tr("Jazda swobodna"), Callable(self, "_on_mode_pressed").bind(GameModes.FREE_DRIVE))
	_add_option_button(tr("Wyścig"), Callable(self, "_on_mode_pressed").bind(GameModes.RACE))
	_focus_first_option()


func _show_track_step() -> void:
	_current_step = STEP_TRACK
	_selected_track_id = &""
	_selected_model_index = -1
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


func _show_model_step() -> void:
	_current_step = STEP_MODEL
	_selected_model_index = -1
	_title_label.text = tr("Wybierz samochód")
	_subtitle_label.text = "%s — %s" % [
		_get_mode_label(_selected_mode_id),
		_get_track_label(_selected_track_id),
	]
	_back_button.visible = true
	_clear_options()

	if _car_models.is_empty():
		_show_configuration_error(tr("Brak dostępnych samochodów"))
		return
	for model_index: int in range(_car_models.size()):
		var model: CarModelMenuOption = _car_models[model_index]
		if model != null and model.is_valid():
			_add_option_button(
				model.label,
				Callable(self, "_on_model_pressed").bind(model_index)
			)
	_focus_first_option()


func _show_variant_step() -> void:
	_current_step = STEP_VARIANT
	_title_label.text = tr("Wybierz wariant")
	_subtitle_label.text = _get_selected_model_label()
	_back_button.visible = true
	_clear_options()

	var variants: Array[CarVariantMenuOption] = _get_selected_model_variants()
	if variants.is_empty():
		_show_configuration_error(tr("Brak wariantów dla wybranego modelu"))
		return
	for variant: CarVariantMenuOption in variants:
		if variant != null and variant.is_valid():
			_add_option_button(
				variant.label,
				Callable(self, "_on_variant_pressed").bind(variant.variant_id)
			)
	_focus_first_option()


func _show_loading_step(car_variant_id: StringName) -> void:
	_current_step = STEP_LOADING
	_loading_elapsed = 0.0
	_loading_progress.value = LOADING_PROGRESS_MINIMUM
	_selection_panel.hide()
	_loading_panel.show()
	_loading_details_label.text = "%s — %s\n%s — %s" % [
		_get_mode_label(_selected_mode_id),
		_get_track_label(_selected_track_id),
		_get_selected_model_label(),
		_get_variant_label(car_variant_id),
	]
	show()


func _show_selection_panel() -> void:
	_loading_panel.hide()
	_selection_panel.show()


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
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 48)
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(pressed_callback)
	_options.add_child(button)


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
	_show_model_step()


func _on_model_pressed(model_index: int) -> void:
	if model_index < 0 or model_index >= _car_models.size():
		_show_configuration_error(tr("Wybrany model nie jest dostępny"))
		return
	_selected_model_index = model_index
	_show_variant_step()


func _on_variant_pressed(car_variant_id: StringName) -> void:
	if _current_step != STEP_VARIANT:
		return
	var valid_variant: bool = false
	for variant: CarVariantMenuOption in _get_selected_model_variants():
		if variant.variant_id == car_variant_id:
			valid_variant = true
			break
	if not valid_variant:
		_show_configuration_error(tr("Wybrany wariant nie jest dostępny"))
		return

	_show_loading_step(car_variant_id)
	await get_tree().process_frame
	await get_tree().process_frame

	var phase_before: int = _resolve_game_session_phase()
	selection_completed.emit(_selected_mode_id, _selected_track_id, car_variant_id)
	var phase_after: int = _resolve_game_session_phase()
	if phase_before == GameSessionState.Phase.MENU and phase_after != GameSessionState.Phase.MENU:
		hide()
	elif _current_step == STEP_LOADING:
		reset_menu()
	else:
		show()


func _on_back_pressed() -> void:
	match _current_step:
		STEP_VARIANT:
			_show_model_step()
		STEP_MODEL:
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
	if _selected_model_index < 0 or _selected_model_index >= _car_models.size():
		return tr("Samochód")
	return _car_models[_selected_model_index].label


func _get_variant_label(car_variant_id: StringName) -> String:
	for variant: CarVariantMenuOption in _get_selected_model_variants():
		if variant != null and variant.variant_id == car_variant_id:
			return variant.label
	return tr("Samochód")


func _get_selected_model_variants() -> Array[CarVariantMenuOption]:
	if _selected_model_index < 0 or _selected_model_index >= _car_models.size():
		var empty: Array[CarVariantMenuOption] = []
		return empty
	return _car_models[_selected_model_index].variants.duplicate()


func _resolve_game_session_phase() -> int:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("get_session_phase"):
			return int(node.call("get_session_phase"))
		node = node.get_parent()
	return GameSessionState.Phase.MENU
