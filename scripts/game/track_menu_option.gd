extends RefCounted
class_name TrackMenuOption

var track_id: StringName
var label: String
var recommended_laps: int
var supported_modes: Array[StringName] = []


func _init(
	id: StringName = &"",
	display_label: String = "",
	laps: int = 1,
	modes: Array[StringName] = []
) -> void:
	track_id = id
	label = display_label
	recommended_laps = maxi(laps, 1)
	supported_modes = modes.duplicate() if not modes.is_empty() else GameModes.ALL.duplicate()


func is_valid() -> bool:
	if track_id == &"" or label.strip_edges().is_empty() or supported_modes.is_empty():
		return false
	var used_modes: Dictionary = {}
	for mode_id: StringName in supported_modes:
		if not GameModes.is_supported(mode_id):
			return false
		var mode_key: String = str(mode_id)
		if used_modes.has(mode_key):
			return false
		used_modes[mode_key] = true
	return true


func supports_mode(mode_id: StringName) -> bool:
	return GameModes.is_supported(mode_id) and supported_modes.has(mode_id)
