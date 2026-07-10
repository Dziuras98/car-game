extends RefCounted
class_name TrackMenuOption

var track_id: StringName
var label: String
var recommended_laps: int


func _init(
	id: StringName = &"",
	display_label: String = "",
	laps: int = 1
) -> void:
	track_id = id
	label = display_label
	recommended_laps = maxi(laps, 1)


func is_valid() -> bool:
	return track_id != &"" and not label.strip_edges().is_empty()
