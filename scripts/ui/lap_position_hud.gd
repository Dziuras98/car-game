extends RefCounted
class_name LapPositionHud

var _layer: CanvasLayer
var _lap_label: Label
var _position_label: Label


func build(owner: Node, lap_count: int) -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 12
	_layer.visible = false
	owner.add_child(_layer)

	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(root)

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


func show() -> void:
	if _layer != null:
		_layer.visible = true


func hide() -> void:
	if _layer != null:
		_layer.visible = false


func update(current_lap: int, total_laps: int, position: int, participant_count: int) -> void:
	if _lap_label != null:
		_lap_label.text = "Okrazenie %d/%d" % [current_lap, maxi(total_laps, 1)]
	if _position_label != null:
		_position_label.text = "Pozycja %d/%d" % [position, maxi(participant_count, 1)]
