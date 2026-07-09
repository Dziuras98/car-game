extends RefCounted
class_name RaceHud

var _countdown_layer: CanvasLayer
var _countdown_label: Label
var _lap_layer: CanvasLayer
var _lap_label: Label
var _position_label: Label
var _results_layer: CanvasLayer
var _results_list: VBoxContainer


func build(owner: Node, lap_count: int, return_to_menu_callable: Callable) -> void:
	_build_countdown_ui(owner)
	_build_lap_ui(owner, lap_count)
	_build_results_ui(owner, return_to_menu_callable)


func show_countdown(text: String) -> void:
	if _countdown_layer == null or _countdown_label == null:
		return

	_countdown_label.text = text
	_countdown_layer.visible = true


func hide_countdown() -> void:
	if _countdown_layer != null:
		_countdown_layer.visible = false


func show_lap() -> void:
	if _lap_layer != null:
		_lap_layer.visible = true


func hide_lap() -> void:
	if _lap_layer != null:
		_lap_layer.visible = false


func update_lap(current_lap: int, total_laps: int, position: int, participant_count: int) -> void:
	if _lap_label != null:
		_lap_label.text = "Okrazenie %d/%d" % [current_lap, maxi(total_laps, 1)]
	if _position_label != null:
		_position_label.text = "Pozycja %d/%d" % [position, maxi(participant_count, 1)]


func show_results(result_labels: Array[String]) -> void:
	if _results_layer == null or _results_list == null:
		return

	for child: Node in _results_list.get_children():
		_results_list.remove_child(child)
		child.queue_free()

	for result_index: int in result_labels.size():
		var row: Label = Label.new()
		row.add_theme_font_size_override("font_size", 21)
		row.text = "%d. %s" % [result_index + 1, result_labels[result_index]]
		_results_list.add_child(row)

	_results_layer.visible = true


func hide_results() -> void:
	if _results_layer != null:
		_results_layer.visible = false


func hide_all() -> void:
	hide_results()
	hide_lap()
	hide_countdown()


func _build_countdown_ui(owner: Node) -> void:
	_countdown_layer = CanvasLayer.new()
	_countdown_layer.layer = 20
	_countdown_layer.visible = false
	owner.add_child(_countdown_layer)

	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_countdown_layer.add_child(root)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	_countdown_label = Label.new()
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_size_override("font_size", 92)
	_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.18, 1.0))
	_countdown_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	_countdown_label.add_theme_constant_override("shadow_offset_x", 4)
	_countdown_label.add_theme_constant_override("shadow_offset_y", 4)
	center.add_child(_countdown_label)


func _build_lap_ui(owner: Node, lap_count: int) -> void:
	_lap_layer = CanvasLayer.new()
	_lap_layer.layer = 12
	_lap_layer.visible = false
	owner.add_child(_lap_layer)

	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lap_layer.add_child(root)

	var panel: PanelContainer = PanelContainer.new()
	panel.offset_left = 24.0
	panel.offset_top = 24.0
	panel.offset_right = 246.0
	panel.offset_bottom = 116.0
	root.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	margin.add_child(content)

	_lap_label = Label.new()
	_lap_label.add_theme_font_size_override("font_size", 22)
	_lap_label.text = "Okrazenie 1/%d" % maxi(lap_count, 1)
	content.add_child(_lap_label)

	_position_label = Label.new()
	_position_label.add_theme_font_size_override("font_size", 22)
	_position_label.text = "Pozycja 1/1"
	content.add_child(_position_label)


func _build_results_ui(owner: Node, return_to_menu_callable: Callable) -> void:
	_results_layer = CanvasLayer.new()
	_results_layer.layer = 30
	_results_layer.visible = false
	owner.add_child(_results_layer)

	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_results_layer.add_child(root)

	var background: ColorRect = ColorRect.new()
	background.color = Color(0.02, 0.025, 0.03, 0.88)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
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

	var title: Label = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.text = "Koniec wyscigu"
	content.add_child(title)

	_results_list = VBoxContainer.new()
	_results_list.add_theme_constant_override("separation", 8)
	content.add_child(_results_list)

	var menu_button: Button = Button.new()
	menu_button.text = "Powrot do menu glownego"
	menu_button.custom_minimum_size = Vector2(0, 46)
	if return_to_menu_callable.is_valid():
		menu_button.pressed.connect(return_to_menu_callable)
	content.add_child(menu_button)
