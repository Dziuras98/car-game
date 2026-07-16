extends RefCounted
class_name GameSessionStartTransaction

signal progress_changed(progress: float, stage: ProgressStage)

enum Result {
	OK,
	NOT_CONFIGURED,
	ALREADY_RUNNING,
	UNSUPPORTED_MODE,
	UNAVAILABLE_CAR_VARIANT,
	UNAVAILABLE_TRACK,
	SESSION_BEGIN_REJECTED,
	TRACK_STAGE_FAILED,
	RUNTIME_CONFIGURATION_FAILED,
	PLAYER_SPAWN_FAILED,
	RACE_START_FAILED,
	TRACK_COMMIT_FAILED,
	SESSION_COMMIT_REJECTED,
}

enum ProgressStage {
	VALIDATING,
	CLEARING_RUNTIME,
	PREPARING_TRACK,
	CONFIGURING_RUNTIME,
	SPAWNING_PLAYER,
	STARTING_RACE,
	FINALIZING,
	COMPLETE,
}

var _session_state: GameSessionState
var _car_selection_state: CarSelectionState
var _track_catalog: TrackCatalog
var _reset_runtime: Callable
var _stage_track: Callable
var _configure_runtime: Callable
var _spawn_player: Callable
var _commit_track: Callable
var _finalize_track_commit: Callable
var _configured: bool = false
var _execution_in_progress: bool = false


func configure(
	session_state: GameSessionState,
	car_selection_state: CarSelectionState,
	track_catalog: TrackCatalog,
	reset_runtime: Callable,
	stage_track: Callable,
	configure_runtime: Callable,
	spawn_player: Callable,
	_start_race: Callable,
	commit_track: Callable,
	finalize_track_commit: Callable
) -> bool:
	if _execution_in_progress:
		return false
	if session_state == null or car_selection_state == null or track_catalog == null:
		return false
	if (
		not reset_runtime.is_valid()
		or not stage_track.is_valid()
		or not configure_runtime.is_valid()
		or not spawn_player.is_valid()
		or not commit_track.is_valid()
		or not finalize_track_commit.is_valid()
	):
		return false
	_session_state = session_state
	_car_selection_state = car_selection_state
	_track_catalog = track_catalog
	_reset_runtime = reset_runtime
	_stage_track = stage_track
	_configure_runtime = configure_runtime
	_spawn_player = spawn_player
	_commit_track = commit_track
	_finalize_track_commit = finalize_track_commit
	_configured = true
	return true


func is_configured() -> bool:
	return _configured


func is_execution_in_progress() -> bool:
	return _execution_in_progress


func execute(
	mode_id: StringName,
	track_id: StringName,
	car_variant_id: StringName,
	spawn_global_transform: Transform3D
) -> Result:
	if not _configured:
		return Result.NOT_CONFIGURED
	if _execution_in_progress:
		return Result.ALREADY_RUNNING
	if mode_id != GameModes.FREE_DRIVE:
		return Result.UNSUPPORTED_MODE

	var selected_car_index: int = _car_selection_state.get_car_index_for_variant_id(car_variant_id)
	if selected_car_index < 0:
		return Result.UNAVAILABLE_CAR_VARIANT
	var selected_track: TrackDefinition = _track_catalog.get_track_by_id(track_id)
	if selected_track == null or selected_track.track_id != &"infinite_grid":
		return Result.UNAVAILABLE_TRACK

	_execution_in_progress = true
	_report_progress(0.10, ProgressStage.VALIDATING)
	if not GameSessionState.is_success(_session_state.begin_start()):
		_execution_in_progress = false
		return Result.SESSION_BEGIN_REJECTED

	_report_progress(0.22, ProgressStage.CLEARING_RUNTIME)
	_reset_runtime.call()
	_report_progress(0.40, ProgressStage.PREPARING_TRACK)
	if not bool(await _stage_track.call(selected_track)):
		return _fail(Result.TRACK_STAGE_FAILED)
	_report_progress(0.60, ProgressStage.CONFIGURING_RUNTIME)
	if not bool(_configure_runtime.call()):
		return _fail(Result.RUNTIME_CONFIGURATION_FAILED)
	_report_progress(0.78, ProgressStage.SPAWNING_PLAYER)
	if not bool(_spawn_player.call(selected_car_index, spawn_global_transform)):
		return _fail(Result.PLAYER_SPAWN_FAILED)
	_report_progress(0.92, ProgressStage.FINALIZING)
	if not bool(_commit_track.call()):
		return _fail(Result.TRACK_COMMIT_FAILED)

	var resolved_variant_id: StringName = _car_selection_state.get_variant_id_for_index(selected_car_index)
	var commit_result: GameSessionState.Result = _session_state.commit(
		GameModes.FREE_DRIVE,
		&"infinite_grid",
		resolved_variant_id
	)
	if not GameSessionState.is_success(commit_result):
		return _fail(Result.SESSION_COMMIT_REJECTED)
	_finalize_track_commit.call()
	_report_progress(1.0, ProgressStage.COMPLETE)
	_execution_in_progress = false
	return Result.OK


static func get_failure_message(result: Result) -> String:
	match result:
		Result.NOT_CONFIGURED:
			return "Session-start transaction is not configured."
		Result.ALREADY_RUNNING:
			return "A session-start transaction is already running."
		Result.UNSUPPORTED_MODE:
			return "Only free drive is supported."
		Result.UNAVAILABLE_CAR_VARIANT:
			return "The selected car variant is unavailable."
		Result.UNAVAILABLE_TRACK:
			return "Only the infinite grid is available."
		Result.SESSION_BEGIN_REJECTED:
			return "Session startup was rejected."
		Result.TRACK_STAGE_FAILED:
			return "The infinite grid could not be staged."
		Result.RUNTIME_CONFIGURATION_FAILED:
			return "Free-drive runtime configuration failed."
		Result.PLAYER_SPAWN_FAILED:
			return "The selected car could not be created."
		Result.TRACK_COMMIT_FAILED:
			return "The infinite grid could not be committed."
		Result.SESSION_COMMIT_REJECTED:
			return "Free-drive session commit failed."
		_:
			return ""


func _report_progress(progress: float, stage: ProgressStage) -> void:
	progress_changed.emit(clampf(progress, 0.0, 1.0), stage)


func _fail(result: Result) -> Result:
	if _reset_runtime.is_valid():
		_reset_runtime.call()
	if _session_state != null:
		_session_state.reset()
	_execution_in_progress = false
	return result
