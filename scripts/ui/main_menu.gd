extends CanvasLayer
class_name MainMenu

signal selection_completed(mode_id: String, track_id: String, car_variant_id: StringName)

const STEP_MODE: int = 0
const STEP_TRACK: int = 1
const STEP_MODEL: int = 2
const STEP_VARIANT: int = 3

var _selected_mode_id: String = ""
var _selected_track_id: String = ""
var _selected_model_index: int = -1
var _current_step: int = STEP_MODE
var _car_models: Array[CarModelMenuOption] = []
var _track_options: Array[TrackMenuOption] = []

@onready var _title_label: Label = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var _subtitle_label: Label = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SubtitleLabel
@onready var _options: VBoxContainer = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Options
@onready var _back_button: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BackButton


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_show_mode_step()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(GameInputActions.UI_CANCEL) and _current_step != STEP_MODE:
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func reset_menu() -> void:
	show()
	_show_mode_step()


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
	_current_step = STEP_MODE
	_selected_mode_id = ""
	_selected_track_id = ""
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
	_selected_track_id = ""
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
				Callable(self, "_on_track_pressed").bind(str(track_option.track_id))
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


func _on_mode_pressed(mode_id: String) -> void:
	if not has_valid_options():
		_show_configuration_error(tr("Konfiguracja zawartości jest niepoprawna"))
		return
	_selected_mode_id = mode_id
	_show_track_step()


func _on_track_pressed(track_id: String) -> void:
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
	var valid_variant: bool = false
	for variant: CarVariantMenuOption in _get_selected_model_variants():
		if variant.variant_id == car_variant_id:
			valid_variant = true
			break
	if not valid_variant:
		_show_configuration_error(tr("Wybrany wariant nie jest dostępny"))
		return
	hide()
	selection_completed.emit(_selected_mode_id, _selected_track_id, car_variant_id)


func _on_back_pressed() -> void:
	match _current_step:
		STEP_VARIANT:
			_show_model_step()
		STEP_MODEL:
			_show_track_step()
		STEP_TRACK:
			_show_mode_step()


func _get_mode_label(mode_id: String) -> String:
	return tr("Wyścig") if mode_id == GameModes.RACE else tr("Jazda swobodna")


func _get_track_label(track_id: String) -> String:
	var option: TrackMenuOption = _find_track_option(track_id)
	return option.label if option != null else tr("Nieznany tor")


func _find_track_option(track_id: String) -> TrackMenuOption:
	for option: TrackMenuOption in _track_options:
		if option != null and str(option.track_id) == track_id:
			return option
	return null


func _get_selected_model_label() -> String:
	if _selected_model_index < 0 or _selected_model_index >= _car_models.size():
		return tr("Samochód")
	return _car_models[_selected_model_index].label


func _get_selected_model_variants() -> Array[CarVariantMenuOption]:
	if _selected_model_index < 0 or _selected_model_index >= _car_models.size():
		var empty: Array[CarVariantMenuOption] = []
		return empty
	return _car_models[_selected_model_index].variants.duplicate()
