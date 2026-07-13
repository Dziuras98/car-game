extends EngineAudioSynthesizer
class_name ProfiledEngineAudioSynthesizer

const SUPPORTED_CYLINDER_COUNT: int = 6

@export var profile: EngineAudioProfile
@export var force_full_runtime_generation: bool = false


func _validate_property(property: Dictionary) -> void:
	if property.get("name", "") == "output_volume_boost_db":
		property.hint = PROPERTY_HINT_RANGE
		property.hint_string = "0.0,16.0,0.5"


func should_generate_procedural_audio(delta: float) -> bool:
	if force_full_runtime_generation:
		return true
	return super.should_generate_procedural_audio(delta)


func _ready() -> void:
	cylinders = SUPPORTED_CYLINDER_COUNT
	if profile != null and not profile.apply_to(self):
		set_process(false)
		return
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	super._ready()


func _exit_tree() -> void:
	set_process(false)
	profile = null
	super._exit_tree()
