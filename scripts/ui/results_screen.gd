extends RefCounted
class_name ResultsScreen

const RESULTS_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/results_screen.tscn")

var _layer: CanvasLayer
var _results_list: VBoxContainer


func build(owner: Node, return_to_menu_callable: Callable) -> void:
	_layer = RESULTS_SCREEN_SCENE.instantiate() as CanvasLayer
	owner.add_child(_layer)

	_results_list = _layer.get_node("Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResultsList") as VBoxContainer
	var menu_button: Button = _layer.get_node("Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MenuButton") as Button
	if return_to_menu_callable.is_valid():
		menu_button.pressed.connect(return_to_menu_callable)


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
