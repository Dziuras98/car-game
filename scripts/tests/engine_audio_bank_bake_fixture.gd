extends SceneTree

const STOCK_PROFILE: EngineAudioProfile = preload("res://resources/audio/370z_stock_audio_profile.tres")
const NISMO_PROFILE: EngineAudioProfile = preload("res://resources/audio/370z_nismo_audio_profile.tres")
const OUTPUT_ROOT: String = "res://build/test-logs/baked-engine-audio"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var baker: EngineAudioBankBaker = EngineAudioBankBaker.new()
	var stock_manifest: Dictionary = baker.bake_profile(
		STOCK_PROFILE,
		OUTPUT_ROOT.path_join("370z_stock"),
		"370z_stock"
	)
	var nismo_manifest: Dictionary = baker.bake_profile(
		NISMO_PROFILE,
		OUTPUT_ROOT.path_join("370z_nismo"),
		"370z_nismo"
	)
	if stock_manifest.is_empty() or nismo_manifest.is_empty():
		push_error("[ENGINE_AUDIO_BANK_BAKE_FIXTURE] Offline bank generation failed.")
		quit(1)
		return
	print(
		"[ENGINE_AUDIO_BANK_BAKE_FIXTURE] Baked %d stock and %d NISMO clips at %d Hz."
		% [
			EngineAudioBankBaker.RPM_POINTS.size() * EngineAudioBankBaker.LAYER_NAMES.size(),
			EngineAudioBankBaker.RPM_POINTS.size() * EngineAudioBankBaker.LAYER_NAMES.size(),
			EngineAudioBankBaker.SAMPLE_RATE,
		]
	)
	quit(0)
