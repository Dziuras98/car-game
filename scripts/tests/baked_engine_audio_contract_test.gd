extends SceneTree

const BANK_PATHS: Array[String] = [
	"res://assets/audio/engine/370z_stock/bank.tres",
	"res://assets/audio/engine/370z_nismo/bank.tres",
]
const PLAYER_SCENE_PATHS: Array[String] = [
	"res://scenes/cars/370z.tscn",
	"res://scenes/cars/370z_nismo.tscn",
]
const AI_SCENE_PATHS: Array[String] = [
	"res://scenes/cars/370z_ai.tscn",
	"res://scenes/cars/370z_nismo_ai.tscn",
]

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_banks()
	_test_player_scenes()
	_test_ai_scenes()
	_finish()


func _test_banks() -> void:
	for bank_path: String in BANK_PATHS:
		var bank: EngineAudioSampleBank = load(bank_path) as EngineAudioSampleBank
		_expect(bank != null, "bank resource loads: %s" % bank_path)
		if bank == null:
			continue
		_expect(bank.validate().is_empty(), "bank paths and metadata validate: %s" % bank_path)
		_expect(bank.prepare(), "bank loads all committed WAV clips: %s" % bank_path)
		_expect(bank.sample_rpms.size() == 9, "bank exposes nine RPM anchors: %s" % bank_path)
		_expect(bank.get_loaded_stream_count() == 18, "bank contains coast and load clips for every anchor: %s" % bank_path)
		for index: int in range(bank.sample_rpms.size()):
			_test_wav(bank.get_coast_stream(index), bank, "coast", index)
			_test_wav(bank.get_load_stream(index), bank, "load", index)


func _test_wav(
	audio_stream: AudioStream,
	bank: EngineAudioSampleBank,
	layer_name: String,
	index: int
) -> void:
	var wav: AudioStreamWAV = audio_stream as AudioStreamWAV
	_expect(wav != null, "%s clip imports as AudioStreamWAV at anchor %d" % [layer_name, index])
	if wav == null:
		return
	_expect(wav.mix_rate == bank.sample_rate, "%s clip retains the bank sample rate at anchor %d" % [layer_name, index])
	_expect(not wav.stereo, "%s clip remains mono at anchor %d" % [layer_name, index])
	_expect(absf(wav.get_length() - bank.loop_seconds) <= 0.02, "%s clip retains the configured loop duration at anchor %d" % [layer_name, index])


func _test_player_scenes() -> void:
	for scene_path: String in PLAYER_SCENE_PATHS:
		var packed_scene: PackedScene = load(scene_path) as PackedScene
		_expect(packed_scene != null, "player car scene loads: %s" % scene_path)
		if packed_scene == null:
			continue
		var car: Node = packed_scene.instantiate()
		var audio: Node = car.get_node_or_null("EngineAudio")
		_expect(audio is ProfiledEngineAudioSynthesizer, "player scene uses the profiled live synthesizer: %s" % scene_path)
		_expect(not (audio is BakedEngineAudioPlayer), "player scene does not use the baked runtime player: %s" % scene_path)
		if audio is ProfiledEngineAudioSynthesizer:
			var synth: ProfiledEngineAudioSynthesizer = audio as ProfiledEngineAudioSynthesizer
			_expect(synth.profile != null, "player scene assigns an engine-audio profile: %s" % scene_path)
			_expect(synth.profile == null or synth.profile.is_valid(), "player scene assigns a valid engine-audio profile: %s" % scene_path)
			_expect(synth.force_full_runtime_generation, "player scene bypasses procedural audio LOD and voice budgeting: %s" % scene_path)
		car.free()


func _test_ai_scenes() -> void:
	for scene_path: String in AI_SCENE_PATHS:
		var packed_scene: PackedScene = load(scene_path) as PackedScene
		_expect(packed_scene != null, "AI car scene loads: %s" % scene_path)
		if packed_scene == null:
			continue
		var car: Node = packed_scene.instantiate()
		var audio: Node = car.get_node_or_null("EngineAudio")
		_expect(audio is BakedEngineAudioPlayer, "AI scene uses BakedEngineAudioPlayer: %s" % scene_path)
		_expect(not (audio is ProfiledEngineAudioSynthesizer), "AI scene excludes the profiled live synthesizer: %s" % scene_path)
		_expect(not (audio is EngineAudioSynthesizer), "AI scene excludes the raw live synthesizer: %s" % scene_path)
		if audio is BakedEngineAudioPlayer:
			var baked_audio: BakedEngineAudioPlayer = audio as BakedEngineAudioPlayer
			_expect(baked_audio.bank != null, "AI scene assigns a baked bank: %s" % scene_path)
			_expect(not baked_audio.uses_audio_stream_generator(), "AI scene contains no generator stream: %s" % scene_path)
		car.free()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[BAKED_ENGINE_AUDIO_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[BAKED_ENGINE_AUDIO_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[BAKED_ENGINE_AUDIO_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[BAKED_ENGINE_AUDIO_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[BAKED_ENGINE_AUDIO_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
