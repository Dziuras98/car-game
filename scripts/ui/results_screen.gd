extends RefCounted
class_name ResultsScreen

var _layer: CanvasLayer
var _results_list: VBoxContainer


func build(owner: Node, return_to_menu_callable: Callable) -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 30
	_layer.visible = false
	owner.add_child(_layer)

	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(root)

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


func show(result_labels: Array[String]) -> void:
	if _layer == null or _results_list == null:
		return

	for child: Node in _results_list.get_children():
		_results_list.remove_child(child)
		child.queue_free()

	for result_index: int in result_labels.size():
		var row: Label = Label.new()
		row.add_theme_font_size_override("font_size", 21)
		row.text = "%d. %s" % [result_index + 1, result_labels[result_index]]
		_results_list.add_child(row)

	_layer.visible = true


func hide() -> void:
	if _layer != null:
		_layer.visible = false
