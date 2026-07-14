extends PolonezEngineAudioSynthesizer
class_name PolonezFordPintoEngineAudioSynthesizer


func _ready() -> void:
	family_label = "Ford Pinto 2.0 SOHC carburettor"
	pushrod_clatter_gain = 0.18
	timing_drive_whine_gain = 0.34
	intake_bark_gain = 0.63
	exhaust_boom_gain = 0.88
	upper_valvetrain_gain = 0.26
	carburettor_flutter_gain = 0.34
	injection_tick_gain = 0.03
	flywheel_pulse_gain = 0.37
	diesel_knock_gain = 0.00
	super._ready()
