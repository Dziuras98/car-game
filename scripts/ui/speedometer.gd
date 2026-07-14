extends CanvasLayer
class_name Speedometer

@export var target_path: NodePath
@export_range(1.0, 120.0, 1.0) var display_update_hz: float = 30.0

@onready var _title_label: Label = $Panel/VBoxContainer/Title
@onready var _car_label: Label = $Panel/VBoxContainer/CarRow/CarLabel
@onready var _car_value: Label = %CarValue
@onready var _speed_value: Label = %SpeedValue
@onready var _gear_label: Label = $Panel/VBoxContainer/GearRow/GearLabel
@onready var _gear_value: Label = %GearValue
@onready var _tachometer_gauge: TachometerGauge = %TachometerGauge
@onready var _car: PlayerCarController = _resolve_target_node()

var _configured_car: PlayerCarController
var _configured_specs: CarSpecs
var _configured_redline_rpm: float = -1.0
var _configured_rev_limiter_rpm: float = -1.0
var _display_timer: float = 0.0
var _last_car_display_name: String = ""
var _last_displayed_speed: int = -1
var _last_gear_text: String = ""


func set_target_node(target: PlayerCarController) -> void:
	_car = target
	_reset_tachometer_configuration_cache()
	_last_displayed_speed = -1
	_last_gear_text = ""
	_display_timer = 0.0
	set_process(is_instance_valid(target))
	if is_inside_tree() and is_instance_valid(target) and target.is_inside_tree():
		target_path = get_path_to(target)
		_sync_tachometer_range()
	_update_car_display_name()


func get_displayed_car_name() -> String:
	return _car_value.text if _car_value != null else ""


func _ready() -> void:
	_title_label.text = tr("PRĘDKOŚĆ")
	_car_label.text = tr("Samochód")
	_gear_label.text = tr("BIEG")
	_sync_tachometer_range()
	_update_car_display_name()
	_update_display(0.0)
	set_process(is_instance_valid(_car))


func _process(delta: float) -> void:
	if not is_instance_valid(_car):
		set_process(false)
		return

	_display_timer -= maxf(delta, 0.0)
	if _display_timer > 0.0:
		return
	_display_timer = 1.0 / maxf(display_update_hz, 1.0)

	_sync_tachometer_range()
	_update_display(
		_car.get_speed_kmh(),
		_car.get_engine_rpm(),
		_car.get_gear_text()
	)


func _update_display(speed_kmh: float, engine_rpm: float = 0.0, gear_text: String = "N") -> void:
	var displayed_speed: int = roundi(absf(speed_kmh))
	if _speed_value != null and displayed_speed != _last_displayed_speed:
		_speed_value.text = str(displayed_speed)
		_last_displayed_speed = displayed_speed

	if _tachometer_gauge != null:
		_tachometer_gauge.set_rpm(engine_rpm)

	if _gear_value != null and gear_text != _last_gear_text:
		_gear_value.text = gear_text
		_last_gear_text = gear_text


func _update_car_display_name() -> void:
	var display_name: String = ""
	if is_instance_valid(_car) and _car.car_specs != null:
		var performance_index: int = CarPerformanceIndexCalculator.calculate(_car.car_specs)
		if performance_index > 0:
			display_name = "%s — DPI %d" % [
				tr(_car.car_specs.display_name),
				performance_index,
			]
	if _car_value != null and display_name != _last_car_display_name:
		_car_value.text = display_name
		_last_car_display_name = display_name


func _sync_tachometer_range() -> void:
	if _car == null or _tachometer_gauge == null:
		return
	var specs: CarSpecs = _car.car_specs
	if specs == null:
		return
	if (
		_configured_car == _car
		and _configured_specs == specs
		and is_equal_approx(_configured_redline_rpm, specs.redline_rpm)
		and is_equal_approx(_configured_rev_limiter_rpm, specs.rev_limiter_rpm)
	):
		return

	_configured_car = _car
	_configured_specs = specs
	_configured_redline_rpm = specs.redline_rpm
	_configured_rev_limiter_rpm = specs.rev_limiter_rpm
	_tachometer_gauge.configure_range(specs.rev_limiter_rpm, specs.redline_rpm)


func _reset_tachometer_configuration_cache() -> void:
	_configured_car = null
	_configured_specs = null
	_configured_redline_rpm = -1.0
	_configured_rev_limiter_rpm = -1.0


func _resolve_target_node() -> PlayerCarController:
	var target_path_text: String = str(target_path)
	if target_path_text.is_empty() or not is_inside_tree():
		return null
	return get_node_or_null(target_path) as PlayerCarController
