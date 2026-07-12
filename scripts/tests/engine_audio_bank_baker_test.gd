extends SceneTree

const STOCK_PROFILE: EngineAudioProfile = preload("res://resources/audio/370z_stock_audio_profile.tres")
const SYNTHESIZER_SCRIPT: Script = preload("res://scripts/car/engine_audio.gd")
const OUTPUT_DIRECTORY: String = "user://engine_audio_bank_baker_test"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_remove_output_directory()
	var preset: EngineAudioBakePreset = EngineAudioBakePreset.new()
	preset.bank_id = "test_bank"
	preset.profile = STOCK_PROFILE
	preset.synthesizer_script = SYNTHESIZER_SCRIPT
	preset.output_directory = OUTPUT_DIRECTORY
	preset.sample_rpms = PackedInt32Array([700, 1200])
	preset.sample_rate = 16000
	preset.warmup_seconds = 0.01
	preset.loop_seconds = 0.02
	preset.boundary_correction_seconds = 0.002
	_expect(preset.validate().is_empty(), "a compact test bake preset validates")

	var manifest: Dictionary = EngineAudioBankBaker.new().bake(preset)
	_expect(not manifest.is_empty(), "the generic baker renders a compact bank")
	_expect(int(manifest.get("sample_rate", 0)) == 16000, "the manifest records the preset sample rate")
	_expect(FileAccess.file_exists(OUTPUT_DIRECTORY.path_join("bank_manifest.json")), "the baker writes a JSON manifest")
	_expect(FileAccess.file_exists(OUTPUT_DIRECTORY.path_join("bank.tres")), "the baker writes a runtime bank resource")
	for layer_name: String in EngineAudioBankBaker.LAYER_NAMES:
		for rpm: int in preset.sample_rpms:
			var path: String = OUTPUT_DIRECTORY.path_join("%s_%04d.wav" % [layer_name, rpm])
			_expect(_has_pcm16_wav_header(path), "the baker writes PCM16 WAV data: %s" % path)
	_remove_output_directory()
	_finish()


func _has_pcm16_wav_header(path: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < 44:
		return false
	var riff: String = file.get_buffer(4).get_string_from_ascii()
	file.seek(8)
	var wave: String = file.get_buffer(4).get_string_from_ascii()
	file.seek(20)
	var format_code: int = file.get_16()
	var channel_count: int = file.get_16()
	file.close()
	return riff == "RIFF" and wave == "WAVE" and format_code == 1 and channel_count == 1


func _remove_output_directory() -> void:
	var absolute_path: String = ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	if not DirAccess.dir_exists_absolute(absolute_path):
		return
	var directory: DirAccess = DirAccess.open(OUTPUT_DIRECTORY)
	if directory != null:
		for file_name: String in directory.get_files():
			directory.remove(file_name)
	DirAccess.remove_absolute(absolute_path)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[ENGINE_AUDIO_BANK_BAKER_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[ENGINE_AUDIO_BANK_BAKER_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ENGINE_AUDIO_BANK_BAKER_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[ENGINE_AUDIO_BANK_BAKER_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[ENGINE_AUDIO_BANK_BAKER_TEST] - %s" % failure_message)
	quit(1)
