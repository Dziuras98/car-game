extends PolonezEngineAudioSynthesizer
class_name PolonezCb16EngineAudioSynthesizer


func _ready() -> void:
	family_label = "FSO CB 1.6 OHV carburettor"
	pushrod_clatter_gain = 0.76
	timing_drive_whine_gain = 0.03
	intake_bark_gain = 0.58
	exhaust_boom_gain = 0.78
	upper_valvetrain_gain = 0.12
	carburettor_flutter_gain = 0.48
	injection_tick_gain = 0.02
	flywheel_pulse_gain = 0.35
	diesel_knock_gain = 0.00
	super._ready()
