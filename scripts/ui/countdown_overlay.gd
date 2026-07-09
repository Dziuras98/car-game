extends RefCounted
class_name CountdownOverlay

var _layer: CanvasLayer
var _label: Label


func build(owner: Node) -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 20
	_layer.visible = false
	owner.add_child(_layer)

	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(root)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 92)
	_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.18, 1.0))
	_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	_label.add_theme_constant_override("shadow_offset_x", 4)
	_label.add_theme_constant_override("shadow_offset_y", 4)
	center.add_child(_label)


func show(text: String) -> void:
	if _layer == null or _label == null:
		return

	_label.text = text
	_layer.visible = true


func hide() -> void:
	if _layer != null:
		_layer.visible = false
