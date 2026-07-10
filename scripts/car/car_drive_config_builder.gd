extends RefCounted
class_name CarDriveConfigBuilder

const NON_RUNTIME_PROPERTIES: Array[StringName] = [
	&"display_name",
]


static func build_from_specs(car_specs: CarSpecs) -> CarDriveConfig:
	if car_specs == null:
		push_error("CarDriveConfigBuilder requires a non-null CarSpecs resource.")
		return null
	var validation_errors: PackedStringArray = car_specs.validate()
	if not validation_errors.is_empty():
		push_error("CarDriveConfigBuilder received invalid specs: %s" % "; ".join(validation_errors))
		return null

	var config: CarDriveConfig = CarDriveConfig.new()
	for property: Dictionary in car_specs.get_property_list():
		var property_name: StringName = property.get("name", &"")
		if property_name == &"" or property_name in NON_RUNTIME_PROPERTIES:
			continue
		if not _config_has_property(config, property_name):
			continue
		var usage: int = int(property.get("usage", 0))
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		var value: Variant = car_specs.get(property_name)
		if value is Array:
			value = value.duplicate(true)
		config.set(property_name, value)
	config.sanitize()
	return config


static func get_unmapped_specs_properties(car_specs: CarSpecs) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if car_specs == null:
		return result
	var config: CarDriveConfig = CarDriveConfig.new()
	for property: Dictionary in car_specs.get_property_list():
		var property_name: StringName = property.get("name", &"")
		var usage: int = int(property.get("usage", 0))
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		if property_name in NON_RUNTIME_PROPERTIES:
			continue
		if not _config_has_property(config, property_name):
			result.append(str(property_name))
	return result


static func _config_has_property(config: CarDriveConfig, property_name: StringName) -> bool:
	for property: Dictionary in config.get_property_list():
		if StringName(property.get("name", &"")) == property_name:
			return true
	return false
