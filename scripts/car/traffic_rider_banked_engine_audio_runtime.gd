extends TrafficRiderBankedEngineAudioSynthesizer
class_name TrafficRiderBankedEngineAudioRuntime


func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		super._ready()
		return
	_car = get_parent() as PlayerCarController
	_rng.seed = int(get_instance_id()) ^ 0xB4A9E0
	procedural_voice_group = &"engine"
	procedural_voice_cost = 2
	max_procedural_voices = mini(max_procedural_voices, 8)
	if profile == null or not profile.validate().is_empty():
		push_error("TrafficRiderBankedEngineAudioRuntime requires a valid physical profile.")
		set_process(false)
		return
	_rpm = profile.idle_rpm
	_target_rpm = profile.idle_rpm
	set_process(false)


func _exit_tree() -> void:
	if DisplayServer.get_name() == "headless":
		release_procedural_voice()
		_playback = null
		stream = null
		return
	super._exit_tree()
