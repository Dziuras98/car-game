extends PlayerCarController
class_name BmwE46CarController

func _init() -> void:
	_powertrain_controller = BmwE46PowertrainController.new()

func get_engine_load() -> float:
	if _drive_config == null:
		return 0.0
	if _drive_config.is_torque_converter_automatic():
		if _runtime_state.current_gear == 0:
			return 0.0
		if _runtime_state.current_gear < 0:
			return clampf(_runtime_state.brake_input, 0.0, 1.0)
		return clampf(_runtime_state.throttle_input, 0.0, 1.0)
	return clampf(_powertrain_controller.get_engine_load(_runtime_state), 0.0, 1.0)
