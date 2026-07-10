extends RefCounted
class_name ParticipantRaceState

var car: PlayerCarController
var completed_laps: int = 0
var progress_distance: float = 0.0
var progress_segment_index: int = 0
var has_projection: bool = false
var last_projection_position: Vector3 = Vector3.ZERO
var projection_buffer: RacingLineProjection = RacingLineProjection.new()
var finished: bool = false
var next_checkpoint: int = 1
var rejected_crossings: int = 0


func _init(participant: PlayerCarController = null) -> void:
	car = participant


func reset_projection_tracking() -> void:
	has_projection = false
	progress_segment_index = 0
	progress_distance = 0.0
	last_projection_position = Vector3.ZERO
	projection_buffer.reset()


func reset_checkpoint_sequence() -> void:
	next_checkpoint = 1
