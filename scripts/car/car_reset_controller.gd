extends RefCounted
class_name CarResetController


func capture_start_transform(state: CarRuntimeState, start_transform: Transform3D) -> void:
	state.start_transform = start_transform


func reset_to_start(
	car: CharacterBody3D,
	state: CarRuntimeState,
	config: CarDriveConfig,
	powertrain: CarPowertrainController,
	skid_mark_emitter: SkidMarkEmitter
) -> void:
	car.global_transform = state.start_transform
	car.velocity = Vector3.ZERO
	state.reset_drive_state(config.idle_rpm)
	powertrain.reset(state)
	if skid_mark_emitter != null:
		skid_mark_emitter.reset_timer()
