extends EngineAudioSynthesizer
class_name ProfiledEngineAudioSynthesizer


@export var profile: EngineAudioProfile


func _ready() -> void:
	if profile != null:
		profile.apply_to(self)
	super._ready()
