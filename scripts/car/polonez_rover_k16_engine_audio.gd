extends PolonezEngineAudioSynthesizer
class_name PolonezRoverK16EngineAudioSynthesizer


func _ready() -> void:
	family_label = "Rover K16 1.4 DOHC 16V"
	pushrod_clatter_gain = 0.05
	timing_drive_whine_gain = 0.42
	intake_bark_gain = 0.92
	exhaust_boom_gain = 0.42
	upper_valvetrain_gain = 0.86
	carburettor_flutter_gain = 0.00
	injection_tick_gain = 0.16
	flywheel_pulse_gain = 0.16
	diesel_knock_gain = 0.00
	super._ready()
