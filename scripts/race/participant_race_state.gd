extends RefCounted
class_name ParticipantRaceState

var car: PlayerCarController
var completed_laps: int = 0
var progress_distance: float = 0.0
var progress_segment_index: int = 0
var finished: bool = false
var next_checkpoint: int = 1
var rejected_crossings: int = 0


func _init(participant: PlayerCarController = null) -> void:
	car = participant
