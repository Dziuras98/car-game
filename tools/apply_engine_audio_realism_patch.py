from __future__ import annotations

import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8", newline="\n")


def replace_once(path: str, old: str, new: str) -> None:
    content = read(path)
    count = content.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: expected one occurrence, found {count}: {old[:120]!r}")
    write(path, content.replace(old, new, 1))


def replace_all(path: str, old: str, new: str, minimum: int = 1) -> None:
    content = read(path)
    count = content.count(old)
    if count < minimum:
        raise RuntimeError(f"{path}: expected at least {minimum} occurrences, found {count}: {old[:120]!r}")
    write(path, content.replace(old, new))


def replace_regex(path: str, pattern: str, replacement: str, count: int = 1) -> None:
    content = read(path)
    updated, substitutions = re.subn(pattern, replacement, content, count=count, flags=re.MULTILINE | re.DOTALL)
    if substitutions != count:
        raise RuntimeError(f"{path}: expected {count} regex substitutions, got {substitutions}: {pattern[:120]!r}")
    write(path, updated)


PROCEDURAL_PLAYER = '''extends AudioStreamPlayer3D
class_name ProceduralAudioPlayer3D

@export var procedural_generation_distance: float = 75.0
@export var procedural_distance_check_interval: float = 0.2
@export var procedural_voice_group: StringName = &"default"
@export_range(1, 32, 1) var max_procedural_voices: int = 6
@export_range(1, 8, 1) var procedural_voice_cost: int = 1

# Entries use {"distance_squared": float, "cost": int}. Keeping the historic
# variable name avoids invalidating old test and debug tooling.
static var _voice_distances_by_group: Dictionary = {}

var _audio_lod_check_timer: float = 0.0
var _procedural_generation_active: bool = true


func should_generate_procedural_audio(delta: float) -> bool:
	_audio_lod_check_timer -= maxf(delta, 0.0)
	if _audio_lod_check_timer > 0.0:
		return _procedural_generation_active

	_audio_lod_check_timer = maxf(procedural_distance_check_interval, 0.02)
	_procedural_generation_active = _resolve_audibility_and_budget()
	return _procedural_generation_active


func is_position_audible(source_position: Vector3, listener_position: Vector3) -> bool:
	var safe_distance: float = maxf(procedural_generation_distance, 0.0)
	return source_position.distance_squared_to(listener_position) <= safe_distance * safe_distance


func get_procedural_voice_cost() -> int:
	return maxi(procedural_voice_cost, 1)


func release_procedural_voice() -> void:
	var group_key: String = str(procedural_voice_group)
	var group_entries: Dictionary = _voice_distances_by_group.get(group_key, {})
	group_entries.erase(get_instance_id())
	if group_entries.is_empty():
		_voice_distances_by_group.erase(group_key)
	else:
		_voice_distances_by_group[group_key] = group_entries


func is_procedural_generation_active() -> bool:
	return _procedural_generation_active


static func report_voice_distance(
	group: StringName,
	source_id: int,
	distance_squared: float,
	max_voices: int,
	voice_cost: int = 1
) -> bool:
	return _report_voice_distance(group, source_id, distance_squared, max_voices, voice_cost)


static func reset_voice_budget() -> void:
	_voice_distances_by_group.clear()


func _resolve_audibility_and_budget() -> bool:
	if not is_inside_tree():
		return true
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return true
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return true

	var distance_squared: float = global_position.distance_squared_to(camera.global_position)
	var safe_distance: float = maxf(procedural_generation_distance, 0.0)
	if distance_squared > safe_distance * safe_distance:
		release_procedural_voice()
		return false
	return _report_voice_distance(
		procedural_voice_group,
		get_instance_id(),
		distance_squared,
		max_procedural_voices,
		get_procedural_voice_cost()
	)


static func _report_voice_distance(
	group: StringName,
	source_id: int,
	distance_squared: float,
	max_voices: int,
	voice_cost: int = 1
) -> bool:
	var group_key: String = str(group)
	var group_entries: Dictionary = _voice_distances_by_group.get(group_key, {})
	group_entries[source_id] = {
		"distance_squared": maxf(distance_squared, 0.0),
		"cost": maxi(voice_cost, 1),
	}
	_voice_distances_by_group[group_key] = group_entries

	var source_ids: Array = group_entries.keys()
	source_ids.sort_custom(func(left: Variant, right: Variant) -> bool:
		return float(group_entries[left].get("distance_squared", INF)) < float(
			group_entries[right].get("distance_squared", INF)
		)
	)
	var spent_budget: int = 0
	var safe_budget: int = maxi(max_voices, 1)
	for candidate_id: Variant in source_ids:
		var entry: Dictionary = group_entries[candidate_id]
		var candidate_cost: int = maxi(int(entry.get("cost", 1)), 1)
		if candidate_id == source_id:
			return spent_budget + candidate_cost <= safe_budget
		spent_budget += candidate_cost
	return false
'''

write("scripts/car/procedural_audio_player_3d.gd", PROCEDURAL_PLAYER)

# ---------------------------------------------------------------------------
# Shared VQ/live synthesizer: state progression independent of audio LOD,
# sample-rate-invariant filters, complete shutdown silence and underrun metrics.
# ---------------------------------------------------------------------------
engine_path = "scripts/car/engine_audio.gd"
replace_once(engine_path, "class_name EngineAudioSynthesizer\n\nconst CYLINDER_GAINS", "class_name EngineAudioSynthesizer\n\nconst VQ_CYLINDER_COUNT: int = 6\nconst REFERENCE_SAMPLE_RATE: float = 32000.0\nconst CYLINDER_GAINS")
replace_once(engine_path, "@export_range(1.0, 40.0, 0.5) var throttle_smoothing: float = 18.0\n", "@export_range(1.0, 40.0, 0.5) var throttle_smoothing: float = 18.0\n@export_range(0.08, 0.30, 0.01) var generator_buffer_length: float = 0.15\n")
replace_once(engine_path, "var _engine_running: bool = true\n", "var _engine_running: bool = true\nvar _engine_state_gain: float = 1.0\nvar _startup_progress: float = 1.0\nvar _buffer_underrun_count: int = 0\n")
replace_once(engine_path, "\tmax_procedural_voices = mini(max_procedural_voices, 6)\n", "\tmax_procedural_voices = mini(max_procedural_voices, 6)\n\tprocedural_voice_cost = 3\n")
replace_once(engine_path, "\tgenerator.buffer_length = 0.09\n", "\tgenerator.buffer_length = clampf(generator_buffer_length, 0.08, 0.30)\n")
replace_regex(
    engine_path,
    r"func _process\(delta: float\) -> void:\n.*?\n\nfunc _exit_tree\(\) -> void:",
    '''func _process(delta: float) -> void:
	if not debug_override_enabled and _car == null:
		return
	var safe_delta: float = maxf(delta, 0.0)
	_advance_engine_state(safe_delta)

	var target_rpm: float = debug_rpm if debug_override_enabled else _car.get_engine_rpm()
	var target_load: float = debug_load if debug_override_enabled else _car.get_engine_load()
	var target_throttle: float = debug_throttle if debug_override_enabled else _car.get_throttle_input()
	if _shutdown_remaining > 0.0:
		var shutdown_ratio: float = clampf(_shutdown_remaining / maxf(shutdown_duration, 0.01), 0.0, 1.0)
		target_rpm = _shutdown_start_rpm * shutdown_ratio
		target_load = 0.0
		target_throttle = 0.0
	elif not _engine_running:
		target_rpm = 0.0
		target_load = 0.0
		target_throttle = 0.0
	var point: Dictionary = sanitize_operating_point(
		target_rpm,
		target_load,
		target_throttle,
		_get_idle_rpm(),
		_get_rev_limit_rpm()
	)

	_smoothed_rpm = lerpf(_smoothed_rpm, float(point.rpm), 1.0 - exp(-rpm_smoothing * safe_delta))
	_smoothed_load = lerpf(_smoothed_load, float(point.load), 1.0 - exp(-throttle_smoothing * safe_delta))
	_smoothed_throttle = lerpf(_smoothed_throttle, float(point.throttle), 1.0 - exp(-throttle_smoothing * safe_delta))
	_update_transient_envelopes(float(point.throttle), safe_delta)

	var loudness: float = clampf(
		_smoothed_load * 0.90
		+ _smoothed_throttle * 0.26
		+ _overrun_amount * 0.12
		+ _throttle_transient * 0.08,
		0.0,
		1.0
	)
	volume_db = lerpf(idle_volume_db, load_volume_db, loudness) + output_volume_boost_db
	if should_generate_procedural_audio(safe_delta):
		_fill_audio_buffer()
	_update_debug_state()


func _exit_tree() -> void:'''
)
replace_regex(
    engine_path,
    r"func trigger_engine_start\(\) -> void:\n.*?\n\nfunc generate_test_frames",
    '''func trigger_engine_start() -> void:
	_engine_running = true
	_engine_state_gain = 1.0
	_shutdown_remaining = 0.0
	_startup_remaining = maxf(starter_duration, 0.0)
	_startup_progress = 0.0 if _startup_remaining > 0.0 else 1.0
	_smoothed_rpm = minf(_smoothed_rpm, 230.0)
	_smoothed_load = 0.0
	_smoothed_throttle = 0.0


func trigger_engine_shutdown() -> void:
	_startup_remaining = 0.0
	_startup_progress = 1.0
	_shutdown_remaining = maxf(shutdown_duration, 0.0)
	_shutdown_start_rpm = maxf(_smoothed_rpm, _get_idle_rpm())
	if _shutdown_remaining <= 0.0:
		_engine_running = false
		_engine_state_gain = 0.0
		_clear_audio_tail_state()


func generate_test_frames'''
)
replace_once(engine_path, "\treturn frames\n\n\nstatic func sanitize_operating_point", '''\treturn frames


func generate_stateful_test_frames(frame_count: int) -> PackedFloat32Array:
	var frames := PackedFloat32Array()
	frames.resize(maxi(frame_count, 0))
	for index: int in frames.size():
		frames[index] = _generate_sample()
	return frames


func advance_engine_state_for_test(delta: float) -> void:
	_advance_engine_state(maxf(delta, 0.0))


func get_buffer_underrun_count() -> int:
	return _buffer_underrun_count


static func sample_rate_invariant_alpha(alpha_at_32k: float, sample_rate: float) -> float:
	var safe_alpha: float = clampf(alpha_at_32k, 0.0, 1.0)
	var safe_rate: float = maxf(sample_rate, 1.0)
	return 1.0 - pow(1.0 - safe_alpha, REFERENCE_SAMPLE_RATE / safe_rate)


static func sample_rate_invariant_decay(decay_at_32k: float, sample_rate: float) -> float:
	var safe_decay: float = clampf(decay_at_32k, 0.0, 1.0)
	return pow(safe_decay, REFERENCE_SAMPLE_RATE / maxf(sample_rate, 1.0))


static func bandlimited_frequency(frequency: float, sample_rate: float, nyquist_ratio: float = 0.42) -> float:
	return clampf(frequency, 0.0, maxf(sample_rate, 1.0) * clampf(nyquist_ratio, 0.05, 0.49))


static func sanitize_operating_point''')
replace_regex(
    engine_path,
    r"func _fill_audio_buffer\(\) -> void:\n.*?\n\nfunc _generate_sample",
    '''func _advance_engine_state(delta: float) -> void:
	var safe_delta: float = maxf(delta, 0.0)
	if _startup_remaining > 0.0:
		_startup_remaining = maxf(_startup_remaining - safe_delta, 0.0)
		_startup_progress = 1.0 - clampf(
			_startup_remaining / maxf(starter_duration, 0.01),
			0.0,
			1.0
		)
	else:
		_startup_progress = 1.0

	if _shutdown_remaining > 0.0:
		_shutdown_remaining = maxf(_shutdown_remaining - safe_delta, 0.0)
		var shutdown_progress: float = 1.0 - clampf(
			_shutdown_remaining / maxf(shutdown_duration, 0.01),
			0.0,
			1.0
		)
		_engine_state_gain = 1.0 - _smoothstep(shutdown_progress)
		if _shutdown_remaining <= 0.0:
			_engine_running = false
			_engine_state_gain = 0.0
			_clear_audio_tail_state()
	elif _engine_running:
		_engine_state_gain = 1.0
	else:
		_engine_state_gain = 0.0


func _fill_audio_buffer() -> void:
	if _playback == null:
		return
	_buffer_underrun_count = _playback.get_skips()
	var frames_available: int = _playback.get_frames_available()
	for frame_index: int in frames_available:
		var sample: float = _generate_sample()
		_playback.push_frame(Vector2(sample, sample))


func _generate_sample'''
)
replace_once(engine_path, "\t_idle_noise = lerpf(_idle_noise, _rng.randf_range(-1.0, 1.0), 0.0028)\n", "\t_idle_noise = lerpf(_idle_noise, _rng.randf_range(-1.0, 1.0), sample_rate_invariant_alpha(0.0028, sample_rate))\n")
replace_once(engine_path, "\tvar firing_frequency: float = maxf(firing_frequency_hz(rpm, cylinders) * (1.0 + idle_speed_modulation), 1.0)\n\tvar crank_frequency: float = maxf(rpm / 60.0, 1.0)\n", "\tvar firing_frequency: float = maxf(firing_frequency_hz(rpm, VQ_CYLINDER_COUNT) * (1.0 + idle_speed_modulation), 0.0)\n\tvar crank_frequency: float = maxf(rpm / 60.0, 0.0)\n")
replace_once(engine_path, "\t\t_firing_index = (_firing_index + 1) % 6\n", "\t\t_firing_index = (_firing_index + 1) % VQ_CYLINDER_COUNT\n")
replace_regex(
    engine_path,
    r"\tvar startup_progress: float = 1\.0\n.*?\n\tvar combustion_state_gate: float = .*?\n",
    '''\tvar startup_progress: float = _startup_progress
	var startup_combustion_gate: float = 1.0
	var starter_motor: float = 0.0
	if _startup_remaining > 0.0:
		startup_combustion_gate = _smoothstep((startup_progress - 0.24) / 0.46)
		var starter_frequency: float = 115.0 + startup_progress * 95.0
		_starter_phase = fposmod(_starter_phase + TAU * starter_frequency * delta, TAU)
		var starter_envelope: float = sin(clampf(startup_progress, 0.0, 1.0) * PI)
		starter_motor = (
			sin(_starter_phase) * 0.70
			+ sin(_starter_phase * 2.0) * 0.21
			+ sin(_starter_phase * 3.0) * 0.07
			+ _noise_medium * 0.09
		) * starter_envelope * starter_motor_level

	var combustion_state_gate: float = 1.0
'''
)
replace_once(engine_path, " * ignition_gate * startup_combustion_gate * shutdown_gate * combustion_state_gate", " * ignition_gate * startup_combustion_gate * combustion_state_gate")
replace_once(engine_path, "\t_noise_slow = lerpf(_noise_slow, white_noise, 0.030)\n\t_noise_medium = lerpf(_noise_medium, white_noise, 0.14)\n\t_noise_fast = lerpf(_noise_fast, white_noise, 0.38)\n", "\t_noise_slow = lerpf(_noise_slow, white_noise, sample_rate_invariant_alpha(0.030, sample_rate))\n\t_noise_medium = lerpf(_noise_medium, white_noise, sample_rate_invariant_alpha(0.14, sample_rate))\n\t_noise_fast = lerpf(_noise_fast, white_noise, sample_rate_invariant_alpha(0.38, sample_rate))\n")
replace_regex(
    engine_path,
    r"\tvar sample: float = \(\n.*?\treturn tanh\(driven \* 1\.08\) \* 0\.97",
    '''\tvar engine_sample: float = (
		exhaust_mix
		+ intake_mix
		+ rasp_mix
		+ mechanical_mix
		+ overrun_mix
	) * load_gain * rpm_gain * 0.31
	var sample: float = engine_sample * _engine_state_gain + starter_motor * 0.38

	var dc_decay: float = sample_rate_invariant_decay(0.996, sample_rate)
	var dc_blocked: float = sample - _dc_previous_input + dc_decay * _dc_previous_output
	_dc_previous_input = sample
	_dc_previous_output = dc_blocked
	var driven: float = dc_blocked * db_to_linear(synthesis_gain_db)
	return tanh(driven * 1.08) * 0.97'''
)
replace_once(engine_path, '"firing_frequency_hz": firing_frequency_hz(_smoothed_rpm, cylinders),', '"firing_frequency_hz": firing_frequency_hz(_smoothed_rpm, VQ_CYLINDER_COUNT),')
replace_once(engine_path, '\t\t"engine_running": _engine_running,\n', '\t\t"engine_running": _engine_running,\n\t\t"engine_state_gain": _engine_state_gain,\n\t\t"buffer_underruns": _buffer_underrun_count,\n')
replace_once(engine_path, "func _reset_synthesis_state() -> void:\n", '''func _clear_audio_tail_state() -> void:
	_previous_combustion = 0.0
	_previous_pulse_derivative = 0.0
	_bank_a_low = 0.0
	_bank_a_band = 0.0
	_bank_b_low = 0.0
	_bank_b_band = 0.0
	_exhaust_body_low = 0.0
	_exhaust_body_band = 0.0
	_exhaust_mid_low = 0.0
	_exhaust_mid_band = 0.0
	_exhaust_reflection_low = 0.0
	_exhaust_reflection_band = 0.0
	_intake_low = 0.0
	_intake_band = 0.0
	_intake_plenum_low = 0.0
	_intake_plenum_band = 0.0
	_rasp_low = 0.0
	_rasp_band = 0.0
	_mechanical_low = 0.0
	_mechanical_band = 0.0
	_crackle_envelope = 0.0
	_dc_previous_input = 0.0
	_dc_previous_output = 0.0


func _reset_synthesis_state() -> void:
''')
replace_once(engine_path, "\t_engine_running = true\n\t_dc_previous_input = 0.0\n", "\t_engine_running = true\n\t_engine_state_gain = 1.0\n\t_startup_progress = 1.0\n\t_buffer_underrun_count = 0\n\t_dc_previous_input = 0.0\n")

# ---------------------------------------------------------------------------
# Four-cylinder, BMW inline-six and V8 backends.
# ---------------------------------------------------------------------------
def patch_backend(path: str, prefix: str, clear_fields: list[str]) -> None:
    replace_all(path, "maxf(EngineAudioSynthesizer.firing_frequency_hz(rpm, 4) * (1.0 + idle_wander), 1.0)", "maxf(EngineAudioSynthesizer.firing_frequency_hz(rpm, 4) * (1.0 + idle_wander), 0.0)", minimum=0)
    replace_all(path, "var crank_hz: float = maxf(rpm / 60.0, 1.0)", "var crank_hz: float = maxf(rpm / 60.0, 0.0)", minimum=1)
    content = read(path)
    content = re.sub(rf"({re.escape(prefix)}_slow_noise = lerpf\({re.escape(prefix)}_slow_noise, white_noise, )([0-9.]+)(\))", rf"\1EngineAudioSynthesizer.sample_rate_invariant_alpha(\2, sample_rate)\3", content)
    content = re.sub(rf"({re.escape(prefix)}_mid_noise = lerpf\({re.escape(prefix)}_mid_noise, white_noise, )([0-9.]+)(\))", rf"\1EngineAudioSynthesizer.sample_rate_invariant_alpha(\2, sample_rate)\3", content)
    content = re.sub(rf"({re.escape(prefix)}_fast_noise = lerpf\({re.escape(prefix)}_fast_noise, white_noise, )([0-9.]+)(\))", rf"\1EngineAudioSynthesizer.sample_rate_invariant_alpha(\2, sample_rate)\3", content)
    write(path, content)
    replace_regex(
        path,
        r"\tvar startup_gate: float = 1\.0\n.*?(?=\n\tvar normalized_phase:)",
        '''\tvar startup_gate: float = 1.0
	var starter_motor: float = 0.0
	if _startup_remaining > 0.0:
		var startup_progress: float = _startup_progress
		startup_gate = _smoothstep((startup_progress - 0.20) / 0.52)
		_starter_phase = fposmod(_starter_phase + TAU * (82.0 + startup_progress * 88.0) * delta, TAU)
		starter_motor = (
			sin(_starter_phase) * 0.68
			+ sin(_starter_phase * 2.0) * 0.24
			+ _punto_mid_noise * 0.13
		) * sin(startup_progress * PI) * starter_motor_level
''',
        count=1,
    )
    replace_all(path, "pulse *= ignition_gate * startup_gate * shutdown_gate * running_gate", "pulse *= ignition_gate * startup_gate", minimum=1)
    replace_all(path, "var dc_blocked: float = sample - ", "var dc_decay: float = EngineAudioSynthesizer.sample_rate_invariant_decay(0.995, sample_rate)\n\tvar dc_blocked: float = sample - ", minimum=1)
    content = read(path).replace(" + 0.995 * ", " + dc_decay * ")
    write(path, content)
    marker = "\n\nfunc _update_debug_state() -> void:"
    body = "\n\nfunc _clear_audio_tail_state() -> void:\n\tsuper._clear_audio_tail_state()\n"
    for field in clear_fields:
        body += f"\t{field} = 0.0\n"
    replace_once(path, marker, body + marker)

fiat_path = "scripts/car/fiat_punto_engine_audio.gd"
replace_once(fiat_path, "\tforce_full_runtime_generation = true\n", "")
replace_once(fiat_path, "var _punto_fast_noise: float = 0.0\n", "")
replace_once(fiat_path, "\t_punto_fast_noise = lerpf(_punto_fast_noise, white_noise, 0.42)\n", "")
replace_once(fiat_path, "\t_punto_fast_noise = 0.0\n", "")
patch_backend(fiat_path, "_punto", [
    "_punto_previous_pulse", "_punto_exhaust_low", "_punto_exhaust_band",
    "_punto_intake_low", "_punto_intake_band", "_punto_mechanical_low",
    "_punto_mechanical_band", "_punto_turbo_low", "_punto_turbo_band",
    "_punto_turbo_spool", "_punto_turbo_release", "_punto_dc_input", "_punto_dc_output",
])
replace_once(fiat_path, "\tvar turbo_hz: float = (620.0 + rpm_ratio * 5200.0 + _punto_turbo_spool * 2300.0) * turbo_pitch_scale\n", "\tvar turbo_hz: float = (620.0 + rpm_ratio * 5200.0 + _punto_turbo_spool * 2300.0) * turbo_pitch_scale\n\tturbo_hz = EngineAudioSynthesizer.bandlimited_frequency(turbo_hz, sample_rate)\n")
replace_regex(fiat_path, r"\tvar sample: float = \(\n.*?\t\) \* load_gain \* 0\.33 \+ starter_motor \* 0\.42", '''\tvar engine_sample: float = (
		exhaust_body * (0.68 + exhaust_resonance * 1.08) * low_rpm_weight
		+ exhaust_harmonics * (0.18 + exhaust_roughness * 0.42)
		+ intake_tone * intake_presence * (0.22 + throttle * 1.38 + _throttle_transient * induction_transient)
		+ intake_air
		+ mechanical_tone * (mechanical_noise + diesel_mechanical_clatter * 0.72)
		+ diesel_rattle * 0.30
		+ pulse_derivative * high_rpm_rasp * high_blend * 0.24
		+ turbo_mix
		+ crackle
	) * load_gain * 0.33
	var sample: float = engine_sample * _engine_state_gain + starter_motor * 0.42''')

bmw_path = "scripts/car/bmw_e46_engine_audio.gd"
replace_once(bmw_path, "\tvar collector_hz: float = maxf(\n\t\tinline_six_collector_frequency_hz(rpm) * (1.0 + idle_wander * 0.45),\n\t\t1.0\n\t)\n", "\tvar collector_hz: float = maxf(\n\t\tinline_six_collector_frequency_hz(rpm) * (1.0 + idle_wander * 0.45),\n\t\t0.0\n\t)\n")
patch_backend(bmw_path, "_punto", ["_bmw_previous_collector_pulse"])
replace_once(bmw_path, "\tvar turbo_hz: float = (620.0 + rpm_ratio * 5200.0 + _punto_turbo_spool * 2300.0) * turbo_pitch_scale\n", "\tvar turbo_hz: float = (620.0 + rpm_ratio * 5200.0 + _punto_turbo_spool * 2300.0) * turbo_pitch_scale\n\tturbo_hz = EngineAudioSynthesizer.bandlimited_frequency(turbo_hz, sample_rate)\n")
replace_regex(bmw_path, r"\tvar sample: float = \(\n.*?\t\) \* load_gain \* lerpf\(0\.33, 0\.29, six_cylinder_blend\) \+ starter_motor \* 0\.42", '''\tvar engine_sample: float = (
		exhaust_body * (0.68 + exhaust_resonance * 1.08) * low_rpm_weight
		+ engine_order * engine_order_gain
		+ intake_tone * intake_presence * (0.22 + throttle * 1.38 + _throttle_transient * induction_transient)
		+ plenum_harmonic
		+ intake_air
		+ mechanical_tone * (mechanical_noise + diesel_mechanical_clatter * 0.72)
		+ diesel_rattle * 0.30
		+ rasp_impulse * high_rpm_rasp * high_blend * 0.24
		+ turbo_mix
		+ crackle
	) * load_gain * lerpf(0.33, 0.29, six_cylinder_blend)
	var sample: float = engine_sample * _engine_state_gain + starter_motor * 0.42''')

polonez_path = "scripts/car/polonez_engine_audio.gd"
replace_once(polonez_path, "\tforce_full_runtime_generation = true\n", "")
replace_all(polonez_path, "maxf(\n\t\tEngineAudioSynthesizer.firing_frequency_hz(rpm, 4) * (1.0 + idle_wander),\n\t\t1.0\n\t)", "maxf(\n\t\tEngineAudioSynthesizer.firing_frequency_hz(rpm, 4) * (1.0 + idle_wander),\n\t\t0.0\n\t)")
replace_all(polonez_path, "var crank_hz: float = maxf(rpm / 60.0, 1.0)", "var crank_hz: float = maxf(rpm / 60.0, 0.0)")
content = read(polonez_path)
content = content.replace("_pnz_slow_noise = lerpf(_pnz_slow_noise, white_noise, 0.014)", "_pnz_slow_noise = lerpf(_pnz_slow_noise, white_noise, EngineAudioSynthesizer.sample_rate_invariant_alpha(0.014, sample_rate))")
content = content.replace("_pnz_mid_noise = lerpf(_pnz_mid_noise, white_noise, 0.105)", "_pnz_mid_noise = lerpf(_pnz_mid_noise, white_noise, EngineAudioSynthesizer.sample_rate_invariant_alpha(0.105, sample_rate))")
write(polonez_path, content)
replace_regex(polonez_path, r"\tvar startup_gate: float = 1\.0\n.*?(?=\n\tvar normalized_phase:)", '''\tvar startup_gate: float = 1.0
	var starter_motor: float = 0.0
	if _startup_remaining > 0.0:
		var startup_progress: float = _startup_progress
		startup_gate = _smoothstep((startup_progress - 0.20) / 0.52)
		_starter_phase = fposmod(
			_starter_phase + TAU * (78.0 + startup_progress * 86.0) * delta,
			TAU
		)
		starter_motor = (
			sin(_starter_phase) * 0.70
			+ sin(_starter_phase * 2.0) * 0.22
			+ _pnz_mid_noise * 0.11
		) * sin(startup_progress * PI) * starter_motor_level
''')
replace_once(polonez_path, "pulse *= ignition_gate * startup_gate * shutdown_gate * running_gate", "pulse *= ignition_gate * startup_gate")
replace_regex(polonez_path, r"\tvar sample: float = \(\n.*?\t\) \* load_gain \* rpm_gain \* 0\.34 \+ starter_motor \* 0\.42", '''\tvar engine_sample: float = (
		exhaust_body * (0.58 + exhaust_resonance * 0.98 + exhaust_boom_gain * 0.46)
		+ exhaust_mid * (0.14 + exhaust_roughness * 0.62)
		+ intake_tone * intake_presence * intake_bark_gain * (
			0.28 + throttle * 1.50 + _throttle_transient * induction_transient * 1.4
		)
		+ intake_air
		+ carb_flutter * 0.12
		+ mechanical_tone * (mechanical_noise + diesel_mechanical_clatter * 0.70 + 0.15)
		+ pulse_derivative * high_rpm_rasp * high_blend * 0.20
		+ crackle
	) * load_gain * rpm_gain * 0.34
	var sample: float = engine_sample * _engine_state_gain + starter_motor * 0.42''')
replace_once(polonez_path, "\tvar dc_blocked: float = sample - _pnz_dc_input + 0.995 * _pnz_dc_output\n", "\tvar dc_decay: float = EngineAudioSynthesizer.sample_rate_invariant_decay(0.995, sample_rate)\n\tvar dc_blocked: float = sample - _pnz_dc_input + dc_decay * _pnz_dc_output\n")
replace_once(polonez_path, "\n\nfunc _update_debug_state() -> void:", '''

func _clear_audio_tail_state() -> void:
	super._clear_audio_tail_state()
	_pnz_previous_pulse = 0.0
	_pnz_exhaust_low = 0.0
	_pnz_exhaust_band = 0.0
	_pnz_exhaust_mid_low = 0.0
	_pnz_exhaust_mid_band = 0.0
	_pnz_intake_low = 0.0
	_pnz_intake_band = 0.0
	_pnz_mechanical_low = 0.0
	_pnz_mechanical_band = 0.0
	_pnz_dc_input = 0.0
	_pnz_dc_output = 0.0


func _update_debug_state() -> void:''')

v8_path = "scripts/car/cross_plane_v8_engine_audio.gd"
replace_once(v8_path, "\t_idle_noise = lerpf(_idle_noise, _rng.randf_range(-1.0, 1.0), 0.0022)\n", "\t_idle_noise = lerpf(_idle_noise, _rng.randf_range(-1.0, 1.0), sample_rate_invariant_alpha(0.0022, sample_rate))\n")
replace_once(v8_path, "\tvar firing_frequency: float = maxf(firing_frequency_hz(rpm, 8) * (1.0 + idle_speed_variation), 1.0)\n\tvar crank_frequency: float = maxf(rpm / 60.0, 1.0)\n", "\tvar firing_frequency: float = maxf(firing_frequency_hz(rpm, 8) * (1.0 + idle_speed_variation), 0.0)\n\tvar crank_frequency: float = maxf(rpm / 60.0, 0.0)\n")
replace_regex(v8_path, r"\tvar startup_gate: float = 1\.0\n.*?(?=\n\tvar event_bank:)", '''\tvar startup_gate: float = 1.0
	var starter_motor: float = 0.0
	if _startup_remaining > 0.0:
		var startup_progress: float = _startup_progress
		startup_gate = _smoothstep((startup_progress - 0.20) / 0.50)
		var starter_frequency: float = 82.0 + startup_progress * 78.0
		_starter_phase = fposmod(_starter_phase + TAU * starter_frequency * delta, TAU)
		starter_motor = (
			sin(_starter_phase) * 0.72
			+ sin(_starter_phase * 2.0) * 0.20
			+ _noise_medium * 0.12
		) * sin(startup_progress * PI) * starter_motor_level
''')
replace_once(v8_path, "pulse *= cylinder_gain * ignition_gate * startup_gate * shutdown_gate * running_gate", "pulse *= cylinder_gain * ignition_gate * startup_gate")
replace_once(v8_path, "\t_noise_slow = lerpf(_noise_slow, white_noise, 0.022)\n\t_noise_medium = lerpf(_noise_medium, white_noise, 0.12)\n\t_noise_fast = lerpf(_noise_fast, white_noise, 0.34)\n", "\t_noise_slow = lerpf(_noise_slow, white_noise, sample_rate_invariant_alpha(0.022, sample_rate))\n\t_noise_medium = lerpf(_noise_medium, white_noise, sample_rate_invariant_alpha(0.12, sample_rate))\n\t_noise_fast = lerpf(_noise_fast, white_noise, sample_rate_invariant_alpha(0.34, sample_rate))\n")
replace_once(v8_path, "\tvar left_sample: float = (common_mix + left_bank * (0.50 + crossplane_roughness * 0.34)) * scale\n\tvar right_sample: float = (common_mix + right_bank * (0.50 + crossplane_roughness * 0.34)) * scale\n", "\tvar left_sample: float = (common_mix + left_bank * (0.50 + crossplane_roughness * 0.34)) * scale * _engine_state_gain\n\tvar right_sample: float = (common_mix + right_bank * (0.50 + crossplane_roughness * 0.34)) * scale * _engine_state_gain\n")
replace_once(v8_path, "\tvar left_dc: float = left_sample - _dc_left_input + 0.996 * _dc_left_output\n", "\tvar dc_decay: float = sample_rate_invariant_decay(0.996, sample_rate)\n\tvar left_dc: float = left_sample - _dc_left_input + dc_decay * _dc_left_output\n")
replace_once(v8_path, "\tvar right_dc: float = right_sample - _dc_right_input + 0.996 * _dc_right_output\n", "\tvar right_dc: float = right_sample - _dc_right_input + dc_decay * _dc_right_output\n")
replace_once(v8_path, "\n\nfunc _update_debug_state() -> void:", '''

func _clear_audio_tail_state() -> void:
	super._clear_audio_tail_state()
	_bank_a_thump = 0.0
	_bank_b_thump = 0.0
	_doublet_envelope = 0.0
	_header_a_low = 0.0
	_header_a_band = 0.0
	_header_b_low = 0.0
	_header_b_band = 0.0
	_rumble_low = 0.0
	_rumble_band = 0.0
	_common_body_low = 0.0
	_common_body_band = 0.0
	_common_mid_low = 0.0
	_common_mid_band = 0.0
	_carb_low = 0.0
	_carb_band = 0.0
	_metal_low = 0.0
	_metal_band = 0.0
	_dc_left_input = 0.0
	_dc_left_output = 0.0
	_dc_right_input = 0.0
	_dc_right_output = 0.0
	_last_stereo_frame = Vector2.ZERO


func _update_debug_state() -> void:''')

# ---------------------------------------------------------------------------
# Profile diagnostics: preserve permissive application, but report meaningful
# unsupported non-default controls instead of silently dropping them.
# ---------------------------------------------------------------------------
profile_path = "scripts/car/engine_audio_profile.gd"
replace_once(profile_path, "const CHARACTER_PROPERTY_NAMES: Array[StringName] = [", '''const PROFILE_METADATA_NAMES: Array[StringName] = [
	&"engine_layout",
	&"firing_order",
	&"aspiration",
	&"family_id",
]
const CHARACTER_PROPERTY_NAMES: Array[StringName] = [''')
replace_regex(profile_path, r"func apply_to\(engine_audio: Object\) -> bool:\n.*?\n\treturn true", '''func apply_to(engine_audio: Object) -> bool:
	if engine_audio == null:
		return false
	var validation_errors: PackedStringArray = validate()
	if not validation_errors.is_empty():
		push_error("EngineAudioProfile is invalid: %s" % "; ".join(validation_errors))
		return false
	var supported_properties: Dictionary = {}
	for target_property: Dictionary in engine_audio.get_property_list():
		supported_properties[StringName(target_property.get("name", &""))] = true
	var defaults: EngineAudioProfile = EngineAudioProfile.new()
	var ignored_non_default: PackedStringArray = PackedStringArray()
	for property: Dictionary in get_property_list():
		var property_name: StringName = property.get("name", &"")
		var usage: int = int(property.get("usage", 0))
		if property_name == &"" or usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		if property_name in [&"script", &"resource_local_to_scene", &"resource_name", &"resource_path"]:
			continue
		if supported_properties.has(property_name):
			engine_audio.set(property_name, get(property_name))
			continue
		if property_name in PROFILE_METADATA_NAMES:
			continue
		if defaults.get(property_name) != get(property_name):
			ignored_non_default.append(str(property_name))
	if not ignored_non_default.is_empty():
		push_warning(
			"EngineAudioProfile ignored unsupported non-default controls on %s: %s"
			% [engine_audio.get_class(), ", ".join(ignored_non_default)]
		)
	return true''')

# ---------------------------------------------------------------------------
# Baked playback: weighted budget, phase-preserving resume and profile-timed
# start/stop fades.
# ---------------------------------------------------------------------------
baked_path = "scripts/car/baked_engine_audio_player.gd"
replace_once(baked_path, "@export_range(0.5, 2.0, 0.01) var maximum_pitch_scale: float = 1.35\n", "@export_range(0.5, 2.0, 0.01) var maximum_pitch_scale: float = 1.35\n@export_range(0.02, 0.50, 0.01) var resume_fade_seconds: float = 0.10\n")
replace_once(baked_path, "var _engine_running: bool = true\n", "var _engine_running: bool = true\nvar _virtual_loop_phase: float = 0.0\nvar _resume_gain: float = 1.0\nvar _was_suspended: bool = false\n")
replace_once(baked_path, "\tmax_procedural_voices = mini(max_procedural_voices, 6)\n", "\tmax_procedural_voices = mini(max_procedural_voices, 6)\n\tprocedural_voice_cost = 2\n")
replace_once(baked_path, "\tvar target_engine_gain: float = 1.0 if _engine_running else 0.0\n\t_engine_gain = move_toward(_engine_gain, target_engine_gain, safe_delta * 4.0)\n", '''\tvar target_engine_gain: float = 1.0 if _engine_running else 0.0
	var transition_seconds: float = bank.startup_duration if _engine_running else bank.shutdown_duration
	_engine_gain = move_toward(
		_engine_gain,
		target_engine_gain,
		safe_delta / maxf(transition_seconds, 0.01)
	)
	var phase_anchor: int = bank.find_nearest_anchor_index(_smoothed_rpm)
	_virtual_loop_phase = fposmod(
		_virtual_loop_phase + safe_delta * _get_pitch_scale(_smoothed_rpm, phase_anchor),
		maxf(bank.loop_seconds, 0.001)
	)
''')
replace_once(baked_path, "\tif not should_generate_procedural_audio(safe_delta):\n\t\t_suspend_playback()\n\t\treturn\n\n\tvar anchor_index", "\tif not should_generate_procedural_audio(safe_delta):\n\t\t_suspend_playback()\n\t\treturn\n\tif _was_suspended:\n\t\t_was_suspended = false\n\t\t_resume_gain = 0.0\n\t_resume_gain = move_toward(_resume_gain, 1.0, safe_delta / maxf(resume_fade_seconds, 0.01))\n\n\tvar anchor_index")
replace_once(baked_path, "\tvar coast_gain: float = cos(_smoothed_load_mix * PI * 0.5) * _engine_gain\n\tvar loaded_gain: float = sin(_smoothed_load_mix * PI * 0.5) * _engine_gain\n", "\tvar coast_gain: float = cos(_smoothed_load_mix * PI * 0.5) * _engine_gain * _resume_gain\n\tvar loaded_gain: float = sin(_smoothed_load_mix * PI * 0.5) * _engine_gain * _resume_gain\n")
replace_once(baked_path, "func get_active_voice_count() -> int:\n", '''func get_procedural_voice_cost() -> int:
	for layer: LayerPlaybackState in [_coast_layer, _load_layer]:
		if layer.transition_anchor_index >= 0:
			return 4
	return 2


func get_active_voice_count() -> int:
''')
replace_once(baked_path, "\t\tlayer.transition_elapsed = 0.0\n\n\nfunc _update_layer", "\t\tlayer.transition_elapsed = 0.0\n\t_was_suspended = true\n\n\nfunc _update_layer")
replace_once(baked_path, "\t\t\t0.0\n\t\t)\n", "\t\t\t_virtual_loop_phase\n\t\t)\n", )

bank_path = "scripts/car/engine_audio_sample_bank.gd"
replace_once(bank_path, "@export_range(0.0, 16.0, 0.5) var output_volume_boost_db: float = 0.0\n", "@export_range(0.0, 16.0, 0.5) var output_volume_boost_db: float = 0.0\n@export_range(0.05, 3.0, 0.05) var startup_duration: float = 0.80\n@export_range(0.05, 3.0, 0.05) var shutdown_duration: float = 1.10\n")
replace_once(bank_path, "\t_append_volume_error(errors, \"output_volume_boost_db\", output_volume_boost_db)\n", "\t_append_volume_error(errors, \"output_volume_boost_db\", output_volume_boost_db)\n\tif not is_finite(startup_duration) or startup_duration <= 0.0:\n\t\terrors.append(\"startup_duration must be finite and positive\")\n\tif not is_finite(shutdown_duration) or shutdown_duration <= 0.0:\n\t\terrors.append(\"shutdown_duration must be finite and positive\")\n")

# ---------------------------------------------------------------------------
# Baker: seam selection + equal-power boundary crossfade, staged writes and
# safer cleanup that never removes unrelated WAV files.
# ---------------------------------------------------------------------------
baker_path = "scripts/tools/engine_audio_bank_baker.gd"
replace_once(baker_path, "\t\t\"output_volume_boost_db\": float(preset.profile.get(\"output_volume_boost_db\")),\n", "\t\t\"output_volume_boost_db\": float(preset.profile.get(\"output_volume_boost_db\")),\n\t\t\"startup_duration\": float(preset.profile.get(\"starter_duration\")),\n\t\t\"shutdown_duration\": float(preset.profile.get(\"shutdown_duration\")),\n")
replace_once(baker_path, "\t_close_loop_boundary(loop_samples, preset)\n", "\t_rotate_to_best_seam(loop_samples)\n\t_close_loop_boundary(loop_samples, preset)\n")
replace_regex(baker_path, r"func _close_loop_boundary\(samples: PackedFloat32Array, preset: EngineAudioBakePreset\) -> void:\n.*?(?=\n\nfunc _write_pcm16_mono_wav)", '''func _rotate_to_best_seam(samples: PackedFloat32Array) -> void:
	if samples.size() < 8:
		return
	var best_index: int = 1
	var best_score: float = INF
	for index: int in range(1, samples.size() - 1):
		var incoming_slope: float = samples[index] - samples[index - 1]
		var outgoing_slope: float = samples[index + 1] - samples[index]
		var score: float = absf(incoming_slope) + absf(outgoing_slope - incoming_slope) * 0.35
		if score < best_score:
			best_score = score
			best_index = index
	if best_index <= 0:
		return
	var rotated := PackedFloat32Array()
	rotated.resize(samples.size())
	for index: int in samples.size():
		rotated[index] = samples[(best_index + index) % samples.size()]
	for index: int in samples.size():
		samples[index] = rotated[index]


func _close_loop_boundary(samples: PackedFloat32Array, preset: EngineAudioBakePreset) -> void:
	if samples.size() < 4 or preset.boundary_correction_seconds <= 0.0:
		return
	var correction_frame_count: int = clampi(
		roundi(float(preset.sample_rate) * preset.boundary_correction_seconds),
		2,
		maxi(samples.size() / 4, 2)
	)
	for offset_index: int in range(correction_frame_count):
		var ratio: float = float(offset_index + 1) / float(correction_frame_count + 1)
		var tail_weight: float = cos(ratio * PI * 0.5)
		var head_weight: float = sin(ratio * PI * 0.5)
		var sample_index: int = samples.size() - correction_frame_count + offset_index
		samples[sample_index] = (
			samples[sample_index] * tail_weight
			+ samples[offset_index] * head_weight
		)
''')
replace_once(baker_path, "\t\t\"output_volume_boost_db = %s\" % float(manifest[\"output_volume_boost_db\"]),\n", "\t\t\"output_volume_boost_db = %s\" % float(manifest[\"output_volume_boost_db\"]),\n\t\t\"startup_duration = %s\" % float(manifest[\"startup_duration\"]),\n\t\t\"shutdown_duration = %s\" % float(manifest[\"shutdown_duration\"]),\n")
replace_regex(baker_path, r"func _remove_previous_generated_files\(output_directory: String\) -> void:\n.*?(?=\n\nfunc _has_property)", '''func _remove_previous_generated_files(output_directory: String) -> void:
	var directory: DirAccess = DirAccess.open(output_directory)
	if directory == null:
		return
	for file_name: String in directory.get_files():
		if _is_generated_bank_file(file_name):
			directory.remove(file_name)


func _is_generated_bank_file(file_name: String) -> bool:
	return (
		(file_name.begins_with("coast_") and file_name.ends_with(".wav"))
		or (file_name.begins_with("load_") and file_name.ends_with(".wav"))
		or file_name == "bank.tres"
		or file_name == "bank_manifest.json"
	)
''')

# ---------------------------------------------------------------------------
# Regression coverage. Test discovery automatically runs every SceneTree file.
# ---------------------------------------------------------------------------
TEST = '''extends SceneTree

class LodBlockedSynthesizer extends EngineAudioSynthesizer:
	func should_generate_procedural_audio(_delta: float) -> bool:
		return false

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_shutdown_progresses_without_audio_generation()
	_test_shutdown_reaches_digital_silence()
	_test_vq_backend_is_explicitly_six_cylinder()
	_test_sample_rate_helpers()
	_test_weighted_voice_budget()
	_finish()


func _test_shutdown_progresses_without_audio_generation() -> void:
	var synthesizer := LodBlockedSynthesizer.new()
	synthesizer.debug_override_enabled = true
	synthesizer.debug_rpm = 3200.0
	synthesizer.trigger_engine_shutdown()
	synthesizer._process(synthesizer.shutdown_duration + 0.05)
	var state: Dictionary = synthesizer.get_debug_state()
	_expect(not bool(state.get("engine_running", true)), "shutdown state advances while procedural LOD is blocked")
	_expect(float(state.get("engine_state_gain", 1.0)) <= 0.000001, "blocked shutdown reaches zero engine gain")
	synthesizer.free()


func _test_shutdown_reaches_digital_silence() -> void:
	var synthesizer := EngineAudioSynthesizer.new()
	synthesizer.generate_test_frames(2048, 3500.0, 0.7, 0.6)
	synthesizer.trigger_engine_shutdown()
	synthesizer.advance_engine_state_for_test(synthesizer.shutdown_duration + 0.05)
	var frames: PackedFloat32Array = synthesizer.generate_stateful_test_frames(4096)
	_expect(_peak(frames) <= 0.000001, "completed shutdown produces digital silence")
	synthesizer.free()


func _test_vq_backend_is_explicitly_six_cylinder() -> void:
	var four_setting := EngineAudioSynthesizer.new()
	four_setting.cylinders = 4
	var six_setting := EngineAudioSynthesizer.new()
	six_setting.cylinders = 6
	var four_frames: PackedFloat32Array = four_setting.generate_test_frames(4096, 3000.0, 0.5, 0.5)
	var six_frames: PackedFloat32Array = six_setting.generate_test_frames(4096, 3000.0, 0.5, 0.5)
	_expect(_mean_abs_difference(four_frames, six_frames) <= 0.000001, "base VQ backend does not pretend to model non-V6 firing geometry")
	four_setting.free()
	six_setting.free()


func _test_sample_rate_helpers() -> void:
	var alpha_16k: float = EngineAudioSynthesizer.sample_rate_invariant_alpha(0.03, 16000.0)
	var alpha_32k: float = EngineAudioSynthesizer.sample_rate_invariant_alpha(0.03, 32000.0)
	var alpha_48k: float = EngineAudioSynthesizer.sample_rate_invariant_alpha(0.03, 48000.0)
	_expect(alpha_16k > alpha_32k and alpha_32k > alpha_48k, "per-sample smoothing scales with sample rate")
	_expect(is_equal_approx(alpha_32k, 0.03), "32 kHz remains the calibrated reference response")
	_expect(EngineAudioSynthesizer.bandlimited_frequency(20000.0, 32000.0) <= 13440.001, "oscillator frequency stays below the configured anti-alias ceiling")


func _test_weighted_voice_budget() -> void:
	ProceduralAudioPlayer3D.reset_voice_budget()
	_expect(ProceduralAudioPlayer3D.report_voice_distance(&"engine-test", 1, 1.0, 6, 2), "first two-cost baked voice receives budget")
	_expect(ProceduralAudioPlayer3D.report_voice_distance(&"engine-test", 2, 4.0, 6, 2), "second two-cost baked voice receives budget")
	_expect(ProceduralAudioPlayer3D.report_voice_distance(&"engine-test", 3, 9.0, 6, 2), "third two-cost baked voice fills budget")
	_expect(not ProceduralAudioPlayer3D.report_voice_distance(&"engine-test", 4, 16.0, 6, 2), "fourth baked voice is rejected when stream cost exceeds budget")
	ProceduralAudioPlayer3D.reset_voice_budget()


func _peak(samples: PackedFloat32Array) -> float:
	var result: float = 0.0
	for sample: float in samples:
		result = maxf(result, absf(sample))
	return result


func _mean_abs_difference(left: PackedFloat32Array, right: PackedFloat32Array) -> float:
	var count: int = mini(left.size(), right.size())
	if count <= 0:
		return 0.0
	var total: float = 0.0
	for index: int in count:
		total += absf(left[index] - right[index])
	return total / float(count)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[ENGINE_AUDIO_RUNTIME_REGRESSION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[ENGINE_AUDIO_RUNTIME_REGRESSION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ENGINE_AUDIO_RUNTIME_REGRESSION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[ENGINE_AUDIO_RUNTIME_REGRESSION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[ENGINE_AUDIO_RUNTIME_REGRESSION_TEST] - %s" % failure_message)
	quit(1)
'''
write("scripts/tests/engine_audio_runtime_regression_test.gd", TEST)

# Remove this one-shot automation from the resulting source branch.
for helper in [
    ROOT / "tools/apply_engine_audio_realism_patch.py",
    ROOT / ".github/workflows/apply-engine-audio-realism.yml",
]:
    if helper.exists():
        helper.unlink()

print("Engine audio realism patch applied successfully.")
