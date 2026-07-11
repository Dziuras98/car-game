extends Node3D

@onready var _audio: EngineAudioSynthesizer = $EngineAudio
@onready var _status: Label = $CanvasLayer/Panel/Margin/VBox/Status

var _rpm: float = 700.0
var _load: float = 0.05
var _throttle: float = 0.04


func _ready() -> void:
	_audio.debug_override_enabled = true
	_apply()


func _process(delta: float) -> void:
	var rpm_axis: float = Input.get_axis(GameInputActions.GEAR_DOWN, GameInputActions.GEAR_UP)
	var load_axis: float = Input.get_axis(GameInputActions.BRAKE, GameInputActions.ACCELERATE)
	_rpm = clampf(_rpm + rpm_axis * 2400.0 * delta, 500.0, 7800.0)
	_load = clampf(_load + load_axis * 0.75 * delta, 0.0, 1.0)
	_throttle = lerpf(_throttle, _load, 1.0 - exp(-10.0 * delta))
	if Input.is_action_just_pressed(GameInputActions.SWITCH_CAR):
		_rpm = 7600.0 if _rpm < 7000.0 else 700.0
		_load = 1.0 if _rpm > 7000.0 else 0.05
		_throttle = _load
	_apply()


func _apply() -> void:
	_audio.debug_rpm = _rpm
	_audio.debug_load = _load
	_audio.debug_throttle = _throttle
	var state: Dictionary = _audio.get_debug_state()
	_status.text = "RPM: %d\nLoad: %.2f\nThrottle: %.2f\nFiring: %.1f Hz\nLimiter: %s\nOverrun: %.2f\nInduction transient: %.2f\n\nGear up/down: RPM\nAccelerate/brake: load\nSwitch car: idle / limiter" % [
		int(_rpm),
		_load,
		_throttle,
		float(state.get("firing_frequency_hz", 0.0)),
		"active" if bool(state.get("limiter_active", false)) else "inactive",
		float(state.get("overrun", 0.0)),
		float(state.get("induction_transient", 0.0)),
	]
