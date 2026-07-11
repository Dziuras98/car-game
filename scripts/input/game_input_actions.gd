extends RefCounted
class_name GameInputActions

const ACCELERATE: StringName = &"accelerate"
const BRAKE: StringName = &"brake"
const STEER_LEFT: StringName = &"steer-left"
const STEER_RIGHT: StringName = &"steer-right"
const HANDBRAKE: StringName = &"handbrake"
const RESET_CAR: StringName = &"reset-car"
const CAMERA_BACK: StringName = &"camera-back"
const PAUSE: StringName = &"pause"
const SWITCH_CAR: StringName = &"switch-car"
const GEAR_UP: StringName = &"gear-up"
const GEAR_DOWN: StringName = &"gear-down"
const UI_CANCEL: StringName = &"ui_cancel"

const REQUIRED_ACTIONS: Array[StringName] = [
	ACCELERATE,
	BRAKE,
	STEER_LEFT,
	STEER_RIGHT,
	HANDBRAKE,
	RESET_CAR,
	CAMERA_BACK,
	PAUSE,
	SWITCH_CAR,
	GEAR_UP,
	GEAR_DOWN,
]

const ANALOG_ACTIONS: Array[StringName] = [
	ACCELERATE,
	BRAKE,
	STEER_LEFT,
	STEER_RIGHT,
]

const MAX_ANALOG_DEADZONE: float = 0.5


static func is_analog_action(action_name: StringName) -> bool:
	return ANALOG_ACTIONS.has(action_name)
