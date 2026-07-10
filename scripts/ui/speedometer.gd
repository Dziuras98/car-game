extends CanvasLayer

@export var target_path: NodePath
@export_range(1.0, 120.0, 1.0) var display_update_hz: float = 30.0

@onready var _speed_value: Label = %SpeedValue
@onready var _gear_value: Label = %GearValue
@onready var _tachometer_gauge: TachometerGauge = %TachometerGauge
@onready var _car: PlayerCarController = _resolve_target_node()

var _configured_car: PlayerCarController
var _display_timer: float = 0.0
var _last_displayed_speed: int = -1
var _last_gear_text: String = ""


func set_target_node(target: PlayerCarController) -> void:
	_car = target
	_configured_car = null
	_last_displayed_speed = -1
	_last_gear_text = ""
	_display_timer = 0.0
	if is_inside_tree() and target != null:
		target_path = get_path_to(target)
		_sync_tachometer_range()


func _ready() -> void:
	_sync_tachometer_range()
	_update_display(0.0)


func _process(delta: float) -> void:
	if not is_instance_valid(_car):
		_car = _resolve_target_node()
		if _car == null:
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
