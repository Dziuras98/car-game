extends CanvasLayer

signal selection_completed(mode_id: String, track_id: String, car_index: int)

@export var car_names: PackedStringArray = ["370Z automat", "370Z manual"]
@export var track_names: PackedStringArray = ["Prosty owal"]

const MODE_FREE: String = "free_drive"
const MODE_RACE: String = "race"
const TRACK_SIMPLE_OVAL: String = "simple_oval"
const STEP_MODE: int = 0
const STEP_TRACK: int = 1
const STEP_CAR: int = 2

var _selected_mode_id: String = ""
var _selected_track_id: String = ""
var _current_step: int = STEP_MODE
var _title_label: Label
var _subtitle_label: Label
var _options: VBoxContainer
var _back_button: Button


func _ready() -> void:
	_build_ui()
	_show_mode_step()


func reset_menu() -> void:
	show()
	_show_mode_step()


func _build_ui() -> void:
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var background: ColorRect = ColorRect.new()
	background.color = Color(0.04, 0.055, 0.07, 0.96)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 34)
	content.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_subtitle_label)

	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 10)
	content.add_child(_options)

	_back_button = Button.new()
	_back_button.text = "Wstecz"
	_back_button.custom_minimum_size = Vector2(0, 42)
	_back_button.pressed.connect(_on_back_pressed)
	content.add_child(_back_button)


func _show_mode_step() -> void:
	_current_step = STEP_MODE
	_selected_mode_id = ""
	_selected_track_id = ""
	_title_label.text = "Car Game"
	_subtitle_label.text = "Wybierz tryb"
	_back_button.visible = false
	_clear_options()
	_add_option_button("Dowolny", Callable(self, "_on_mode_pressed").bind(MODE_FREE))
	_add_option_button("Wyscig", Callable(self, "_on_mode_pressed").bind(MODE_RACE))


func _show_track_step() -> void:
	_current_step = STEP_TRACK
	_selected_track_id = ""
	_title_label.text = "Wybierz tor"
	_subtitle_label.text = "Tryb: %s" % _get_mode_label(_selected_mode_id)
	_back_button.visible = true
	_clear_options()

	for track_index: int in range(track_names.size()):
		var track_label: String = track_names[track_index]
		var track_id: String = TRACK_SIMPLE_OVAL
		_add_option_button(track_label, Callable(self, "_on_track_pressed").bind(track_id))


func _show_car_step() -> void:
	_current_step = STEP_CAR
	_title_label.text = "Wybierz samochod"
	_subtitle_label.text = "%s - %s" % [_get_mode_label(_selected_mode_id), _get_track_label(_selected_track_id)]
	_back_button.visible = true
	_clear_options()

	for car_index: int in range(car_names.size()):
		_add_option_button(car_names[car_index], Callable(self, "_on_car_pressed").bind(car_index))


func _clear_options() -> void:
	for child: Node in _options.get_children():
		_options.remove_child(child)
		child.queue_free()


func _add_option_button(text: String, pressed_callback: Callable) -> void:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 48)
	button.pressed.connect(pressed_callback)
	_options.add_child(button)


func _on_mode_pressed(mode_id: String) -> void:
	_selected_mode_id = mode_id
	_show_track_step()


func _on_track_pressed(track_id: String) -> void:
	_selected_track_id = track_id
	_show_car_step()


func _on_car_pressed(car_index: int) -> void:
	hide()
	selection_completed.emit(_selected_mode_id, _selected_track_id, car_index)


func _on_back_pressed() -> void:
	if _current_step == STEP_CAR:
		_show_track_step()
	else:
		_show_mode_step()


func _get_mode_label(mode_id: String) -> String:
	if mode_id == MODE_RACE:
		return "Wyscig"
	return "Dowolny"


func _get_track_label(track_id: String) -> String:
	if track_id == TRACK_SIMPLE_OVAL and not track_names.is_empty():
		return track_names[0]
	return "Prosty owal"
