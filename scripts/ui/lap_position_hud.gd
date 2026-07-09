extends RefCounted
class_name LapPositionHud

const LAP_POSITION_HUD_SCENE: PackedScene = preload("res://scenes/ui/lap_position_hud.tscn")

var _layer: CanvasLayer
var _lap_label: Label
var _position_label: Label


func build(owner: Node, lap_count: int) -> void:
	_layer = LAP_POSITION_HUD_SCENE.instantiate() as CanvasLayer
	owner.add_child(_layer)

	_lap_label = _layer.get_node("Root/Panel/Margin/Content/LapLabel") as Label
	_lap_label.text = "Okrazenie 1/%d" % maxi(lap_count, 1)
	_position_label = _layer.get_node("Root/Panel/Margin/Content/PositionLabel") as Label
	_position_label.text = "Pozycja 1/1"


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
