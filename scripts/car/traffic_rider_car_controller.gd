extends PlayerCarController
class_name TrafficRiderCarController

@export_group("Traffic Rider powertrain")
@export var traffic_rider_powertrain_definition: TrafficRiderPowertrainDefinition


func _init() -> void:
	_powertrain_controller = TrafficRiderPowertrainController.new()


func _initialize_drive_runtime() -> SpecsApplyResult:
	var controller := _get_traffic_rider_powertrain_controller()
	controller.set_powertrain_definition(_resolve_powertrain_definition(_car_specs))
	var result: SpecsApplyResult = super._initialize_drive_runtime()
	if result != SpecsApplyResult.OK:
		return result
	if controller.has_valid_powertrain_definition():
		return SpecsApplyResult.OK
	_report_definition_errors(controller.get_powertrain_definition_errors())
	return SpecsApplyResult.INVALID_SPECS


func try_apply_car_specs(next_specs: CarSpecs) -> SpecsApplyResult:
	if next_specs == null:
		push_warning("PlayerCarController rejected null CarSpecs; keeping the active runtime configuration.")
		return SpecsApplyResult.NULL_SPECS
	var next_config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(next_specs, false)
	if next_config == null:
		push_warning("PlayerCarController rejected invalid CarSpecs; keeping the active runtime configuration.")
		return SpecsApplyResult.INVALID_SPECS
	var next_definition: TrafficRiderPowertrainDefinition = _resolve_powertrain_definition(next_specs)
	if next_definition == null:
		push_warning("PlayerCarController rejected Traffic Rider specs without a powertrain definition.")
		return SpecsApplyResult.INVALID_SPECS
	var definition_errors: PackedStringArray = next_definition.validate_for(next_config)
	if not definition_errors.is_empty():
		push_warning("PlayerCarController rejected invalid Traffic Rider powertrain definition: %s" % "; ".join(definition_errors))
		return SpecsApplyResult.INVALID_SPECS
	var controller := _get_traffic_rider_powertrain_controller()
	controller.set_powertrain_definition(next_definition)
	_car_specs = next_specs
	_apply_drive_config(next_config, true)
	if not controller.has_valid_powertrain_definition():
		push_warning("PlayerCarController rejected invalid CarSpecs; keeping the active runtime configuration.")
		return SpecsApplyResult.INVALID_SPECS
	return SpecsApplyResult.OK


func get_selected_gear() -> int:
	return _get_traffic_rider_powertrain_controller().get_selected_gear()


func get_engaged_gear() -> int:
	return _get_traffic_rider_powertrain_controller().get_engaged_gear()


func get_transmission_shift_phase() -> int:
	return _get_traffic_rider_powertrain_controller().get_shift_phase()


func get_transmission_shift_progress() -> float:
	return _get_traffic_rider_powertrain_controller().get_shift_progress()


func get_converter_speed_ratio() -> float:
	return _get_traffic_rider_powertrain_controller().get_converter_speed_ratio()


func get_converter_slip_rpm() -> float:
	return _get_traffic_rider_powertrain_controller().get_converter_slip_rpm()


func get_lockup_engagement() -> float:
	return _get_traffic_rider_powertrain_controller().get_lockup_engagement()


func get_dynamic_front_torque_fraction() -> float:
	return _get_traffic_rider_powertrain_controller().get_dynamic_front_torque_fraction()


func get_transfer_clutch_temperature_c() -> float:
	return _get_traffic_rider_powertrain_controller().get_transfer_clutch_temperature_c()


func _resolve_powertrain_definition(specs: CarSpecs) -> TrafficRiderPowertrainDefinition:
	var traffic_specs: TrafficRiderCarSpecs = specs as TrafficRiderCarSpecs
	if traffic_specs != null and traffic_specs.traffic_rider_powertrain_definition != null:
		return traffic_specs.traffic_rider_powertrain_definition
	return traffic_rider_powertrain_definition


func _get_traffic_rider_powertrain_controller() -> TrafficRiderPowertrainController:
	return _powertrain_controller as TrafficRiderPowertrainController


func _report_definition_errors(errors: PackedStringArray) -> void:
	if errors.is_empty():
		push_error("Traffic Rider powertrain definition is invalid.")
		return
	for error_message: String in errors:
		push_error("Traffic Rider powertrain definition: %s" % error_message)
