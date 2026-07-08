extends CanvasLayer

@export var target_path: NodePath

@onready var _speed_value: Label = %SpeedValue
@onready var _gear_value: Label = %GearValue
@onready var _tachometer_gauge: TachometerGauge = %TachometerGauge
@onready var _car: PlayerCarController = get_node_or_null(target_path) as PlayerCarController


func set_target_node(target: PlayerCarController) -> void:
	_car = target
	if is_inside_tree() and target != null:
		target_path = get_path_to(target)


func _ready() -> void:
	_update_display(0.0)


func _process(_delta: float) -> void:
	if not is_instance_valid(_car):
		_car = get_node_or_null(target_path) as PlayerCarController
		if _car == null:
			return

	var speed_kmh: float = _car.get_speed_kmh()
	var engine_rpm: float = _car.get_engine_rpm()
	var gear_text: String = _car.get_gear_text()
	_update_display(speed_kmh, engine_rpm, gear_text)


func _update_display(speed_kmh: float, engine_rpm: float = 0.0, gear_text: String = "N") -> void:
	var displayed_speed: float = absf(speed_kmh)
	_speed_value.text = str(roundi(displayed_speed))
	_tachometer_gauge.set_rpm(engine_rpm)
	_gear_value.text = gear_text
