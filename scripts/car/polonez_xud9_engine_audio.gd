extends PolonezEngineAudioSynthesizer
class_name PolonezXud9EngineAudioSynthesizer


func _ready() -> void:
	family_label = "PSA XUD9A 1.9 indirect-injection diesel"
	pushrod_clatter_gain = 0.20
	timing_drive_whine_gain = 0.20
	intake_bark_gain = 0.18
	exhaust_boom_gain = 0.64
	upper_valvetrain_gain = 0.05
	carburettor_flutter_gain = 0.00
	injection_tick_gain = 0.12
	flywheel_pulse_gain = 0.44
	diesel_knock_gain = 1.00
	super._ready()
