extends AudioStreamPlayer3D
class_name BakedEngineAudioPlayer

const SILENT_VOLUME_DB: float = -80.0
const MIN_LINEAR_GAIN: float = 0.0001

class LayerPlaybackState:
	var players: Array[AudioStreamPlayer3D] = []
	var active_player_index: int = 0
	var anchor_index: int = -1
	var transition_anchor_index: int = -1
	var transition_elapsed: float = 0.0


@export var bank: EngineAudioSampleBank
@export_range(0.02, 0.50, 0.01) var anchor_crossfade_seconds: float = 0.12
@export_range(1.0, 40.0, 0.5) var rpm_smoothing: float = 14.0
@export_range(1.0, 40.0, 0.5) var load_smoothing: float = 16.0
@export_range(0.5, 2.0, 0.01) var minimum_pitch_scale: float = 0.75
@export_range(0.5, 2.0, 0.01) var maximum_pitch_scale: float = 1.35

var _car: PlayerCarController
var _coast_layer: LayerPlaybackState = LayerPlaybackState.new()
var _load_layer: LayerPlaybackState = LayerPlaybackState.new()
var _smoothed_rpm: float = 700.0
var _smoothed_load_mix: float = 0.0
var _engine_gain: float = 1.0
var _engine_running: bool = true


func _ready() -> void:
	stop()
	stream = null
	_car = get_parent() as PlayerCarController
	if bank == null or not bank.is_valid() or _car == null:
		push_error("BakedEngineAudioPlayer requires a valid bank and PlayerCarController parent.")
		set_process(false)
		return
	_create_layer_players(_coast_layer, "Coast")
	_create_layer_players(_load_layer, "Load")
	_smoothed_rpm = maxf(_car.get_engine_rpm(), bank.sample_rpms[0])
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	set_process(true)


func _process(delta: float) -> void:
	if _car == null or bank == null:
		set_process(false)
		return
	var safe_delta: float = maxf(delta, 0.0)
	var target_rpm: float = maxf(_car.get_engine_rpm(), bank.sample_rpms[0])
	var target_load_mix: float = clampf(
		_car.get_engine_load() * 0.82 + _car.get_throttle_input() * 0.28,
		0.0,
		1.0
	)
	_smoothed_rpm = lerpf(
		_smoothed_rpm,
		target_rpm,
		1.0 - exp(-rpm_smoothing * safe_delta)
	)
	_smoothed_load_mix = lerpf(
		_smoothed_load_mix,
		target_load_mix,
		1.0 - exp(-load_smoothing * safe_delta)
	)
	var target_engine_gain: float = 1.0 if _engine_running else 0.0
	_engine_gain = move_toward(_engine_gain, target_engine_gain, safe_delta * 4.0)

	var anchor_index: int = bank.find_nearest_anchor_index(_smoothed_rpm)
	var coast_gain: float = cos(_smoothed_load_mix * PI * 0.5) * _engine_gain
	var load_gain: float = sin(_smoothed_load_mix * PI * 0.5) * _engine_gain
	_update_layer(
		_coast_layer,
		false,
		anchor_index,
		_smoothed_rpm,
		coast_gain,
		bank.idle_volume_db + bank.output_volume_boost_db,
		safe_delta
	)
	_update_layer(
		_load_layer,
		true,
		anchor_index,
		_smoothed_rpm,
		load_gain,
		bank.load_volume_db + bank.output_volume_boost_db,
		safe_delta
	)


func trigger_engine_start() -> void:
	_engine_running = true
	_engine_gain = 0.0


func trigger_engine_shutdown() -> void:
	_engine_running = false


func is_using_baked_bank() -> bool:
	return bank != null and bank.is_valid()


func get_selected_anchor_rpm() -> float:
	return bank.get_anchor_rpm(_coast_layer.anchor_index) if bank != null else 0.0


func get_active_voice_count() -> int:
	var active_count: int = 0
	for layer: LayerPlaybackState in [_coast_layer, _load_layer]:
		for player: AudioStreamPlayer3D in layer.players:
			if player.playing and player.volume_db > SILENT_VOLUME_DB + 0.1:
				active_count += 1
	return active_count


func _exit_tree() -> void:
	set_process(false)
	for layer: LayerPlaybackState in [_coast_layer, _load_layer]:
		for player: AudioStreamPlayer3D in layer.players:
			if is_instance_valid(player):
				player.stop()
	_car = null


func _create_layer_players(state: LayerPlaybackState, prefix: String) -> void:
	for channel_index: int in range(2):
		var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		player.name = "%sChannel%d" % [prefix, channel_index + 1]
		_copy_spatial_settings(player)
		player.volume_db = SILENT_VOLUME_DB
		add_child(player)
		state.players.append(player)


func _copy_spatial_settings(player: AudioStreamPlayer3D) -> void:
	player.attenuation_model = attenuation_model
	player.unit_size = unit_size
	player.max_db = max_db
	player.max_distance = max_distance
	player.panning_strength = panning_strength
	player.doppler_tracking = doppler_tracking
	player.bus = bus


func _update_layer(
	state: LayerPlaybackState,
	use_load_streams: bool,
	target_anchor_index: int,
	target_rpm: float,
	layer_gain: float,
	base_volume_db: float,
	delta: float
) -> void:
	if target_anchor_index < 0 or state.players.size() != 2:
		return
	if state.anchor_index < 0:
		state.anchor_index = target_anchor_index
		_start_channel(
			state.players[state.active_player_index],
			_get_stream(use_load_streams, target_anchor_index),
			target_rpm,
			target_anchor_index,
			0.0
		)
	elif (
		target_anchor_index != state.anchor_index
		and state.transition_anchor_index < 0
	):
		var inactive_index: int = 1 - state.active_player_index
		var phase: float = fposmod(
			state.players[state.active_player_index].get_playback_position(),
			bank.loop_seconds
		)
		state.transition_anchor_index = target_anchor_index
		state.transition_elapsed = 0.0
		_start_channel(
			state.players[inactive_index],
			_get_stream(use_load_streams, target_anchor_index),
			target_rpm,
			target_anchor_index,
			phase
		)

	var master_volume_db: float = volume_db + base_volume_db
	if state.transition_anchor_index >= 0:
		_update_transitioning_layer(state, target_rpm, layer_gain, master_volume_db, delta)
	else:
		var active_player: AudioStreamPlayer3D = state.players[state.active_player_index]
		active_player.pitch_scale = _get_pitch_scale(target_rpm, state.anchor_index)
		active_player.volume_db = _gain_to_volume_db(layer_gain, master_volume_db)
		var inactive_player: AudioStreamPlayer3D = state.players[1 - state.active_player_index]
		inactive_player.volume_db = SILENT_VOLUME_DB
		if inactive_player.playing:
			inactive_player.stop()


func _update_transitioning_layer(
	state: LayerPlaybackState,
	target_rpm: float,
	layer_gain: float,
	master_volume_db: float,
	delta: float
) -> void:
	var inactive_index: int = 1 - state.active_player_index
	var active_player: AudioStreamPlayer3D = state.players[state.active_player_index]
	var next_player: AudioStreamPlayer3D = state.players[inactive_index]
	state.transition_elapsed += delta
	var duration: float = maxf(anchor_crossfade_seconds, 0.02)
	var ratio: float = clampf(state.transition_elapsed / duration, 0.0, 1.0)
	var smooth_ratio: float = ratio * ratio * (3.0 - 2.0 * ratio)
	var active_weight: float = cos(smooth_ratio * PI * 0.5)
	var next_weight: float = sin(smooth_ratio * PI * 0.5)
	active_player.pitch_scale = _get_pitch_scale(target_rpm, state.anchor_index)
	next_player.pitch_scale = _get_pitch_scale(target_rpm, state.transition_anchor_index)
	active_player.volume_db = _gain_to_volume_db(layer_gain * active_weight, master_volume_db)
	next_player.volume_db = _gain_to_volume_db(layer_gain * next_weight, master_volume_db)
	if ratio < 1.0:
		return
	active_player.stop()
	active_player.volume_db = SILENT_VOLUME_DB
	state.active_player_index = inactive_index
	state.anchor_index = state.transition_anchor_index
	state.transition_anchor_index = -1
	state.transition_elapsed = 0.0


func _start_channel(
	player: AudioStreamPlayer3D,
	audio_stream: AudioStream,
	target_rpm: float,
	anchor_index: int,
	phase: float
) -> void:
	if audio_stream == null:
		return
	_prepare_loop(audio_stream)
	player.stream = audio_stream
	player.pitch_scale = _get_pitch_scale(target_rpm, anchor_index)
	player.volume_db = SILENT_VOLUME_DB
	player.play(clampf(phase, 0.0, maxf(bank.loop_seconds - 0.001, 0.0)))


func _prepare_loop(audio_stream: AudioStream) -> void:
	if not audio_stream is AudioStreamWAV:
		return
	var wav: AudioStreamWAV = audio_stream as AudioStreamWAV
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = maxi(roundi(float(wav.mix_rate) * bank.loop_seconds), 1)


func _get_stream(use_load_streams: bool, anchor_index: int) -> AudioStream:
	return (
		bank.get_load_stream(anchor_index)
		if use_load_streams
		else bank.get_coast_stream(anchor_index)
	)


func _get_pitch_scale(target_rpm: float, anchor_index: int) -> float:
	return clampf(
		target_rpm / bank.get_anchor_rpm(anchor_index),
		minimum_pitch_scale,
		maximum_pitch_scale
	)


func _gain_to_volume_db(linear_gain: float, base_volume_db: float) -> float:
	if linear_gain <= MIN_LINEAR_GAIN:
		return SILENT_VOLUME_DB
	return maxf(base_volume_db + linear_to_db(linear_gain), SILENT_VOLUME_DB)
