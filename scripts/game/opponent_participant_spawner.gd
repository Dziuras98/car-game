extends RefCounted
class_name OpponentParticipantSpawner

signal driver_fault(message: String)

enum Result {
	OK,
	INVALID_COUNT,
	NOT_CONFIGURED,
	NO_ELIGIBLE_VARIANTS,
	PREPARATION_FAILED,
}

var _last_spawn_result: Result = Result.NOT_CONFIGURED


static func is_success(result: Result) -> bool:
	return result == Result.OK


func configure(
	_owner_node: Node3D,
	_car_spawn: Node3D,
	_track: GeneratedTrack,
	_factory: CarInstanceFactory,
	_layout: OpponentSpawnLayout,
	_paint_randomizer: OpponentPaintRandomizer,
	_session_seed: int
) -> void:
	_last_spawn_result = Result.NO_ELIGIBLE_VARIANTS


func is_configured() -> bool:
	return false


func get_last_spawn_result() -> Result:
	return _last_spawn_result


func get_opponents() -> Array[PlayerCarController]:
	var empty: Array[PlayerCarController] = []
	return empty


func get_ai_drivers() -> Array[AiRaceDriver]:
	var empty: Array[AiRaceDriver] = []
	return empty


func spawn_opponents(opponent_count: int) -> Array[PlayerCarController]:
	_last_spawn_result = Result.INVALID_COUNT if opponent_count < 0 else Result.NO_ELIGIBLE_VARIANTS
	if opponent_count > 0:
		push_error("Opponent participants were removed with race mode.")
	var empty: Array[PlayerCarController] = []
	return empty


func clear_opponents() -> void:
	_last_spawn_result = Result.OK


func set_ai_enabled(_enabled: bool) -> void:
	pass
