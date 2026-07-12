extends Node3D
class_name CarVisualController


@export var detailed_root_path: NodePath = ^"SketchfabModel"
@export var low_detail_root_path: NodePath = ^"LowDetail"
@export_range(5.0, 250.0, 1.0) var detail_switch_distance: float = 55.0
@export_range(0.0, 50.0, 1.0) var detail_switch_hysteresis: float = 8.0
@export_range(0.1, 1.0, 0.01) var visual_wheel_radius: float = 0.34
@export var force_low_detail: bool = false

var _detailed_root: Node3D
var _low_detail_root: Node3D
var _wheel_nodes: Array[Node3D] = []
var _wheel_base_rotations: Array[Vector3] = []
var _front_wheel_flags: Array[bool] = []
var _wheel_spin: float = 0.0
var _using_low_detail: bool = false


func _ready() -> void:
	_detailed_root = get_node_or_null(detailed_root_path) as Node3D
	_low_detail_root = get_node_or_null(low_detail_root_path) as Node3D
	_collect_wheel_nodes(self)
	_set_low_detail_active(force_low_detail)
	set_process(not force_low_detail)


func set_force_low_detail(enabled: bool) -> void:
	force_low_detail = enabled
	if is_inside_tree():
		_set_low_detail_active(enabled)
		set_process(not enabled)


func is_using_low_detail() -> bool:
	return _using_low_detail


func get_registered_wheel_count() -> int:
	return _wheel_nodes.size()


func update_vehicle_visuals(
	delta: float,
	forward_speed: float,
	steering_input: float,
	wheel_radius_override: float = -1.0
) -> void:
	var safe_delta: float = maxf(delta, 0.0)
	var radius: float = wheel_radius_override if wheel_radius_override > 0.0 else visual_wheel_radius
	_wheel_spin = fposmod(_wheel_spin + forward_speed / maxf(radius, 0.01) * safe_delta, TAU)
	var steering_angle: float = deg_to_rad(24.0) * clampf(steering_input, -1.0, 1.0)
	for index: int in range(_wheel_nodes.size()):
		var wheel: Node3D = _wheel_nodes[index]
		if not is_instance_valid(wheel):
			continue
		var rotation_value: Vector3 = _wheel_base_rotations[index]
		rotation_value.x += _wheel_spin
		if _front_wheel_flags[index]:
			rotation_value.y += steering_angle
		wheel.rotation = rotation_value


func _process(_delta: float) -> void:
	if force_low_detail:
		_set_low_detail_active(true)
		set_process(false)
		return
	var viewport: Viewport = get_viewport()
	var camera: Camera3D = viewport.get_camera_3d() if viewport != null else null
	if camera == null:
		return
	var distance: float = global_position.distance_to(camera.global_position)
	var switch_to_low_at: float = detail_switch_distance + detail_switch_hysteresis * 0.5
	var switch_to_high_at: float = detail_switch_distance - detail_switch_hysteresis * 0.5
	if _using_low_detail:
		if distance < switch_to_high_at:
			_set_low_detail_active(false)
	elif distance > switch_to_low_at:
		_set_low_detail_active(true)


func _set_low_detail_active(enabled: bool) -> void:
	_using_low_detail = enabled and _low_detail_root != null
	if _detailed_root != null:
		_detailed_root.visible = not _using_low_detail
	if _low_detail_root != null:
		_low_detail_root.visible = _using_low_detail


func _collect_wheel_nodes(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Node3D:
			var child_3d: Node3D = child as Node3D
			var normalized_name: String = child_3d.name.to_lower()
			if (
				"wheel" in normalized_name
				or "tire" in normalized_name
				or "tyre" in normalized_name
				or "rim" in normalized_name
			):
				_register_wheel_node(child_3d, normalized_name)
		_collect_wheel_nodes(child)


func _register_wheel_node(wheel: Node3D, normalized_name: String) -> void:
	if _wheel_nodes.has(wheel):
		return
	_wheel_nodes.append(wheel)
	_wheel_base_rotations.append(wheel.rotation)
	var explicitly_front: bool = "front" in normalized_name or "fl" in normalized_name or "fr" in normalized_name
	_front_wheel_flags.append(explicitly_front or wheel.position.z < 0.0)
