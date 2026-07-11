extends RefCounted
class_name LapPositionHud

const LAP_POSITION_HUD_SCENE: PackedScene = preload("res://scenes/ui/lap_position_hud.tscn")

var _layer: CanvasLayer
var _lap_label: Label
var _position_label: Label
var _last_current_lap: int = -1
var _last_total_laps: int = -1
var _last_position: int = -1
var _last_participant_count: int = -1
var _text_update_count: int = 0


func build(owner: Node, lap_count: int) -> void:
	_layer = LAP_POSITION_HUD_SCENE.instantiate() as CanvasLayer
	owner.add_child(_layer)

	_lap_label = _layer.get_node("Root/Panel/Margin/Content/LapLabel") as Label
	_position_label = _layer.get_node("Root/Panel/Margin/Content/PositionLabel") as Label
	update(1, maxi(lap_count, 1), 1, 1)


func show() -> void:
	if _layer != null:
		_layer.visible = true


func hide() -> void:
	if _layer != null:
		_layer.visible = false


func update(current_lap: int, total_laps: int, position: int, participant_count: int) -> void:
	var safe_total_laps: int = maxi(total_laps, 1)
	var safe_participant_count: int = maxi(participant_count, 1)
	if (
		_lap_label != null
		and (current_lap != _last_current_lap or safe_total_laps != _last_total_laps)
	):
		_lap_label.text = tr("Okrążenie %d/%d") % [current_lap, safe_total_laps]
		_last_current_lap = current_lap
		_last_total_laps = safe_total_laps
		_text_update_count += 1

	if (
		_position_label != null
		and (position != _last_position or safe_participant_count != _last_participant_count)
	):
		_position_label.text = tr("Pozycja %d/%d") % [position, safe_participant_count]
		_last_position = position
		_last_participant_count = safe_participant_count
		_text_update_count += 1


func get_text_update_count() -> int:
	return _text_update_count
