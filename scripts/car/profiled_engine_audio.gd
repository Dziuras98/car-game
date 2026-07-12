extends EngineAudioSynthesizer
class_name ProfiledEngineAudioSynthesizer


@export var profile: EngineAudioProfile


func _validate_property(property: Dictionary) -> void:
	if property.get("name", "") == "output_volume_boost_db":
		property.hint = PROPERTY_HINT_RANGE
		property.hint_string = "0.0,16.0,0.5"


func _ready() -> void:
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
