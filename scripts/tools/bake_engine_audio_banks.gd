extends SceneTree

const DEFAULT_PRESET_PATHS: Array[String] = [
	"res://resources/audio/bake_presets/370z_stock_bake.tres",
	"res://resources/audio/bake_presets/370z_nismo_bake.tres",
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var preset_paths: PackedStringArray = _get_requested_preset_paths()
	if preset_paths.is_empty():
		push_error("[ENGINE_AUDIO_BANK_BAKER] No bake presets were requested.")
		quit(1)
		return
	var baker: EngineAudioBankBaker = EngineAudioBankBaker.new()
	var clip_count: int = 0
	for preset_path: String in preset_paths:
		var preset: EngineAudioBakePreset = load(preset_path) as EngineAudioBakePreset
		if preset == null:
			push_error("[ENGINE_AUDIO_BANK_BAKER] Could not load preset: %s" % preset_path)
			quit(1)
			return
		var manifest: Dictionary = baker.bake(preset)
		if manifest.is_empty():
			push_error("[ENGINE_AUDIO_BANK_BAKER] Failed to bake preset: %s" % preset_path)
			quit(1)
			return
		clip_count += preset.sample_rpms.size() * EngineAudioBankBaker.LAYER_NAMES.size()
		print(
			"[ENGINE_AUDIO_BANK_BAKER] Baked %s to %s."
			% [preset.bank_id, preset.output_directory]
		)
	print("[ENGINE_AUDIO_BANK_BAKER] Completed %d preset(s), %d WAV clips." % [preset_paths.size(), clip_count])
	quit(0)


func _get_requested_preset_paths() -> PackedStringArray:
	var requested: PackedStringArray = PackedStringArray()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--preset="):
			var path: String = argument.trim_prefix("--preset=").strip_edges()
			if not path.is_empty():
				requested.append(path)
		elif argument == "--all":
			requested.clear()
			requested.append_array(DEFAULT_PRESET_PATHS)
	if requested.is_empty():
		requested.append_array(DEFAULT_PRESET_PATHS)
	return requested
