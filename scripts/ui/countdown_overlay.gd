extends RefCounted
class_name CountdownOverlay

const COUNTDOWN_OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/countdown_overlay.tscn")

var _layer: CanvasLayer
var _label: Label


func build(owner: Node) -> void:
	_layer = COUNTDOWN_OVERLAY_SCENE.instantiate() as CanvasLayer
	owner.add_child(_layer)
	_label = _layer.get_node("Root/CenterContainer/Label") as Label


func show(text: String) -> void:
	if _layer == null or _label == null:
		return

	_label.text = text
	_layer.visible = true


func hide() -> void:
	if _layer != null:
		_layer.visible = false
