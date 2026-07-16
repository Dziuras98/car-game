extends CanvasLayer
class_name MainMenu

signal car_selected(car_variant_id: StringName)
# Compatibility signal for old test fixtures. Production uses car_selected.
signal selection_completed(mode_id: StringName, track_id: StringName, car_variant_id: StringName)

const STEP_CAR: int = 0
const STEP_LOADING: int = 1
const LOADING_PROGRESS_INITIAL: float = 4.0
const INFINITE_GRID_ID: StringName = &"infinite_grid"

var _current_step: int = STEP_CAR
var _car_models: Array[CarModelMenuOption] = []
var _flat_car_options: Array[CarVariantMenuOption] = []
var _track_options: Array[TrackMenuOption] = []
var _selected_mode_id: StringName = GameModes.FREE_DRIVE
var _selected_track_id: StringName = INFINITE_GRID_ID

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


func _ready() -> void:
	_back_button.hide()
	_car_selection_panel.hide()
	reset_menu()


func _unhandled_input(event: InputEvent) -> void:
	if visible and _current_step == STEP_LOADING and event.is_action_pressed(GameInputActions.UI_CANCEL):
		get_viewport().set_input_as_handled()


func reset_menu() -> void:
	show()
	_show_car_step()


func is_loading_screen_visible() -> bool:
	return visible and _current_step == STEP_LOADING and _loading_panel.visible


func get_loading_progress() -> float:
	return _loading_progress.value if is_loading_screen_visible() else 0.0


func set_loading_progress(progress: float, status_text: String = "") -> void:
	if not is_loading_screen_visible():
		return
	_loading_progress.value = maxf(
		_loading_progress.value,
		clampf(progress, 0.0, 1.0) * 100.0
	)
	if not status_text.is_empty():
		_loading_subtitle_label.text = status_text


func complete_loading(success: bool) -> void:
	if success:
		hide()
	else:
		reset_menu()


func set_car_models(next_car_models: Array[CarModelMenuOption]) -> void:
	_car_models = next_car_models.duplicate()
	_rebuild_flat_car_options()
	if is_inside_tree() and _current_step == STEP_CAR:
		_show_car_step()


func set_track_options(next_track_options: Array[TrackMenuOption]) -> void:
	# Kept only for source compatibility. Runtime always uses the infinite grid.
	_track_options = next_track_options.duplicate()


func has_valid_options() -> bool:
	if _car_models.is_empty() or _flat_car_options.is_empty():
		return false
	for model: CarModelMenuOption in _car_models:
		if model == null or not model.is_valid():
			return false
	return true


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


func _show_car_step() -> void:
	_current_step = STEP_CAR
	_selected_mode_id = GameModes.FREE_DRIVE
	_selected_track_id = INFINITE_GRID_ID
	_loading_panel.hide()
	_car_selection_panel.hide()
	_selection_panel.show()
	_title_label.text = tr("Car Game")
	_subtitle_label.text = tr("Wybierz samochód")
	_back_button.hide()
	_clear_options()
	if _flat_car_options.is_empty():
		_subtitle_label.text = tr("Brak dostępnych samochodów")
		return
	for variant: CarVariantMenuOption in _flat_car_options:
		_add_option_button(
			"%s — %s" % [variant.model_label, variant.label],
			Callable(self, "_on_car_pressed").bind(variant)
		)
	_focus_first_option()


func _show_loading_step(variant: CarVariantMenuOption) -> void:
	_current_step = STEP_LOADING
	_loading_progress.value = LOADING_PROGRESS_INITIAL
	_loading_subtitle_label.text = tr("Tworzenie samochodu")
	_loading_details_label.text = "%s — %s\n%s" % [
		variant.model_label,
		variant.label,
		tr("Nieskończona siatka"),
	]
	_selection_panel.hide()
	_car_selection_panel.hide()
	_loading_panel.show()
	show()


func _on_car_pressed(variant: CarVariantMenuOption) -> void:
	if variant == null or not variant.is_valid():
		return
	_show_loading_step(variant)
	await get_tree().process_frame
	await get_tree().process_frame
	car_selected.emit(variant.variant_id)
	selection_completed.emit(GameModes.FREE_DRIVE, INFINITE_GRID_ID, variant.variant_id)


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


func _focus_first_option() -> void:
	for child: Node in _options.get_children():
		if child is Button:
			(child as Button).call_deferred("grab_focus")
			return


# Compatibility entry points retained for old fixtures. They all route to car selection.
func _show_mode_step() -> void:
	_show_car_step()


func _show_track_step() -> void:
	_show_car_step()


func _on_mode_pressed(mode_id: StringName) -> void:
	if mode_id == GameModes.FREE_DRIVE:
		_show_car_step()


func _on_track_pressed(_track_id: StringName) -> void:
	_show_car_step()


func _on_back_pressed() -> void:
	_show_car_step()


func _get_mode_label(_mode_id: StringName) -> String:
	return tr("Jazda swobodna")


func _get_track_label(_track_id: StringName) -> String:
	return tr("Nieskończona siatka")


func _find_track_option(track_id: StringName) -> TrackMenuOption:
	for option: TrackMenuOption in _track_options:
		if option != null and option.track_id == track_id:
			return option
	return null
