extends PolonezEngineAudioSynthesizer
class_name PolonezAeAf15EngineAudioSynthesizer


func _ready() -> void:
	family_label = "FSO AE/AF 1.5 OHV single-point injection"
	pushrod_clatter_gain = 0.62
	timing_drive_whine_gain = 0.04
	intake_bark_gain = 0.34
	exhaust_boom_gain = 0.61
	upper_valvetrain_gain = 0.11
	carburettor_flutter_gain = 0.07
	injection_tick_gain = 0.20
	flywheel_pulse_gain = 0.29
	diesel_knock_gain = 0.00
	super._ready()
