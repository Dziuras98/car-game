extends PolonezEngineAudioSynthesizer
class_name PolonezAb15EngineAudioSynthesizer


func _ready() -> void:
	family_label = "FSO AB 1.5 OHV carburettor"
	pushrod_clatter_gain = 0.72
	timing_drive_whine_gain = 0.03
	intake_bark_gain = 0.52
	exhaust_boom_gain = 0.72
	upper_valvetrain_gain = 0.10
	carburettor_flutter_gain = 0.44
	injection_tick_gain = 0.02
	flywheel_pulse_gain = 0.32
	diesel_knock_gain = 0.00
	super._ready()
