extends PolonezEngineAudioSynthesizer
class_name PolonezCeCf16EngineAudioSynthesizer


func _ready() -> void:
	family_label = "FSO CE/CF 1.6 OHV single-point injection"
	pushrod_clatter_gain = 0.66
	timing_drive_whine_gain = 0.04
	intake_bark_gain = 0.39
	exhaust_boom_gain = 0.67
	upper_valvetrain_gain = 0.12
	carburettor_flutter_gain = 0.06
	injection_tick_gain = 0.22
	flywheel_pulse_gain = 0.32
	diesel_knock_gain = 0.00
	super._ready()
