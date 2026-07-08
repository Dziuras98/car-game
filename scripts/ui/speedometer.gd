extends CanvasLayer

@export var target_path: NodePath

@onready var _speed_value: Label = %SpeedValue
@onready var _gear_value: Label = %GearValue
@onready var _tachometer_gauge: TachometerGauge = %TachometerGauge
@onready var _car: PlayerCarController = _resolve_target_node()

var _configured_car: PlayerCarController


func set_target_node(target: PlayerCarController) -> void:
	_car = target
	if is_inside_tree() and target != null:
		target_path = get_path_to(target)
		_sync_tachometer_range()


func _ready() -> void:
	_sync_tachometer_range()
	_update_display(0.0)


func _process(_delta: float) -> void:
	if not is_instance_valid(_car):
		_car = _resolve_target_node()
		if _car == null:
			return

	_sync_tachometer_range()
	var speed_kmh: float = _car.get_speed_kmh()
	var engine_rpm: float = _car.get_engine_rpm()
	var gear_text: String = _car.get_gear_text()
	_update_display(speed_kmh, engine_rpm, gear_text)


func _update_display(speed_kmh: float, engine_rpm: float = 0.0, gear_text: String = "N") -> void:
	var displayed_speed: float = absf(speed_kmh)
	_speed_value.text = str(roundi(displayed_speed))
	_tachometer_gauge.set_rpm(engine_rpm)
	_gear_value.text = gear_text


func _sync_tachometer_range() -> void:
	if _car == null or _tachometer_gauge == null or _configured_car == _car:
		return

	_configured_car = _car
	_tachometer_gauge.configure_range(_car.rev_limiter_rpm, _car.redline_rpm)


func _resolve_target_node() -> PlayerCarController:
	var target_path_text: String = str(target_path)
	if target_path_text.is_empty() or not is_inside_tree():
		return null

	return get_node_or_null(target_path) as PlayerCarController
