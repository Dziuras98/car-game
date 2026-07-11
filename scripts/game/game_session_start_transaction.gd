extends RefCounted
class_name GameSessionStartTransaction


enum Result {
	OK,
	NOT_CONFIGURED,
	UNSUPPORTED_MODE,
	UNAVAILABLE_CAR_VARIANT,
	UNAVAILABLE_TRACK,
	SESSION_BEGIN_REJECTED,
	TRACK_ACTIVATION_FAILED,
	RUNTIME_CONFIGURATION_FAILED,
	PLAYER_SPAWN_FAILED,
	RACE_START_FAILED,
	SESSION_COMMIT_REJECTED,
}


var _session_state: GameSessionState
var _car_selection_state: CarSelectionState
var _track_catalog: TrackCatalog
var _reset_runtime: Callable
var _activate_track: Callable
var _configure_runtime: Callable
var _spawn_player: Callable
var _start_race: Callable
var _configured: bool = false


func configure(
	session_state: GameSessionState,
	car_selection_state: CarSelectionState,
	track_catalog: TrackCatalog,
	reset_runtime: Callable,
	activate_track: Callable,
	configure_runtime: Callable,
	spawn_player: Callable,
	start_race: Callable
) -> bool:
	_configured = false
	if session_state == null or car_selection_state == null or track_catalog == null:
		push_error("GameSessionStartTransaction requires session, car-selection and track-catalog state.")
		return false
	if (
		not reset_runtime.is_valid()
		or not activate_track.is_valid()
		or not configure_runtime.is_valid()
		or not spawn_player.is_valid()
		or not start_race.is_valid()
	):
		push_error("GameSessionStartTransaction requires valid lifecycle callbacks.")
		return false

	_session_state = session_state
	_car_selection_state = car_selection_state
	_track_catalog = track_catalog
	_reset_runtime = reset_runtime
	_activate_track = activate_track
	_configure_runtime = configure_runtime
	_spawn_player = spawn_player
	_start_race = start_race
	_configured = true
	return true


func is_configured() -> bool:
	return _configured


func execute(
	mode_id: StringName,
	track_id: StringName,
	car_variant_id: StringName,
	spawn_global_transform: Transform3D
) -> Result:
	if not _configured:
		return Result.NOT_CONFIGURED
	if not GameModes.is_supported(mode_id):
		return _fail(Result.UNSUPPORTED_MODE)

	var selected_car_index: int = _car_selection_state.get_car_index_for_variant_id(car_variant_id)
	if selected_car_index < 0:
		return _fail(Result.UNAVAILABLE_CAR_VARIANT)
	var selected_track: TrackDefinition = _track_catalog.get_track_by_id(track_id)
	if selected_track == null:
		return _fail(Result.UNAVAILABLE_TRACK)

	_reset_runtime.call()
	if not GameSessionState.is_success(_session_state.begin_start()):
		return _fail(Result.SESSION_BEGIN_REJECTED)
	if not bool(_activate_track.call(selected_track)):
		return _fail(Result.TRACK_ACTIVATION_FAILED)
	if not bool(_configure_runtime.call()):
		return _fail(Result.RUNTIME_CONFIGURATION_FAILED)
	if not bool(_spawn_player.call(selected_car_index, spawn_global_transform)):
		return _fail(Result.PLAYER_SPAWN_FAILED)
	if mode_id == GameModes.RACE and not bool(_start_race.call()):
		return _fail(Result.RACE_START_FAILED)

	var resolved_variant_id: StringName = _car_selection_state.get_variant_id_for_index(selected_car_index)
	var commit_result: GameSessionState.Result = _session_state.commit(
		mode_id,
		selected_track.track_id,
		resolved_variant_id
	)
	if not GameSessionState.is_success(commit_result):
		return _fail(Result.SESSION_COMMIT_REJECTED)
	return Result.OK


static func get_failure_message(result: Result) -> String:
	match result:
		Result.NOT_CONFIGURED:
			return "Session-start transaction is not configured."
		Result.UNSUPPORTED_MODE:
			return "Menu emitted an unsupported gameplay mode."
		Result.UNAVAILABLE_CAR_VARIANT:
			return "Menu emitted an unavailable car variant."
		Result.UNAVAILABLE_TRACK:
			return "Menu emitted an unavailable track."
		Result.SESSION_BEGIN_REJECTED:
			return "Session lifecycle rejected startup from the current state."
		Result.TRACK_ACTIVATION_FAILED:
			return "The selected track could not be activated."
		Result.RUNTIME_CONFIGURATION_FAILED:
			return "Runtime controllers could not be configured for the selected track."
		Result.PLAYER_SPAWN_FAILED:
			return "The selected car could not be created."
		Result.RACE_START_FAILED:
			return "The race could not be started with the complete participant set."
		Result.SESSION_COMMIT_REJECTED:
			return "Session lifecycle rejected the validated session selection."
		_:
			return ""


func _fail(result: Result) -> Result:
	if _reset_runtime.is_valid():
		_reset_runtime.call()
	return result
